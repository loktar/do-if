require File.join(File.dirname(__FILE__), '../lib/do_if')

def it_should_call_the_block(fixture_glob)
  it 'should call the block' do
    called_the_block(fixture_glob).should == true
  end
end

def it_should_not_call_the_block(fixture_glob)
  it 'should not call the block' do
    called_the_block(fixture_glob).should == false
  end
end

def called_the_block(fixture_glob)
  was_called = false
  DoIf.any_file_changed fixture(fixture_glob) do
    was_called = true
  end
  was_called
end

def fixture(path)
  File.join(File.dirname(__FILE__), "fixtures", path).to_s
end

def touch(file_name)
  path = fixture(file_name)
  FileUtils.touch(path)
  new_time = File.mtime(path) + 1
  File.utime(new_time, new_time, path)
end

describe DoIf do
  before do
    DoIf.reset
    %w(empty many_files one_file nested_file/sub_dir).each do |folder|
      %x{rm -f #{fixture(folder)}/*}
    end
    
    FileUtils.touch(fixture('one_file/1'))
    FileUtils.touch(fixture('many_files/1'))
    FileUtils.touch(fixture('many_files/2'))
    FileUtils.touch(fixture('nested_file/sub_dir/1'))
  end

  describe '.reset' do
    it 'should reset the stored state of whether files have changed' do
      called_the_block('one_file/**/*').should == true
      called_the_block('one_file/**/*').should == false
      DoIf.reset
      called_the_block('one_file/**/*').should == true
    end

    it "should handle cases when no state is saved" do
      lambda {
        DoIf.reset
      }.should_not raise_error
    end
  end

  describe '.any_file_changed' do
    describe 'when the specified directory hasnt been run before' do
      it_should_call_the_block 'one_file/**/*'

      it_should_call_the_block 'many_files/**/*'
      
      it_should_call_the_block 'nested_file/**/*'
      
      describe 'when there are no files in the directory' do
        it_should_not_call_the_block 'empty/**/*'
      end
    end
    
    describe 'when called multiple times on a single directory' do
      before do
        DoIf.any_file_changed fixture('one_file/**/*') do end
      end
      
      describe 'when no files have changed since the last run' do
        it_should_not_call_the_block 'one_file/**/*'
      end
      
      describe 'when a file has changed since the last run' do
        before do
          touch('one_file/1')
        end
        
        it_should_call_the_block 'one_file/**/*'
      end

      describe 'when a file has been added since the last run' do
        before do
          touch('many_files/42')
        end
        
        after do
          FileUtils.rm(fixture('many_files/42'))
        end
        
        it_should_call_the_block 'many_files/**/*'
      end
      
      describe 'when a file has been deleted since the last run' do
        before do
          touch('many_files/42')
          DoIf.any_file_changed fixture('many_files/**/*') do end
          FileUtils.rm(fixture('many_files/42'))
        end
        
        it_should_call_the_block 'many_files/**/*'
        
        describe 'when the file was the last file in the directory' do 
          before do
            DoIf.any_file_changed fixture('one_file/**/*') do end
            FileUtils.rm(fixture('one_file/1'))
          end
          
          after do
            touch('one_file/1')
          end
          
          it_should_call_the_block 'one_file/**/*'
        end
      end
    end
  end

  describe '.any_file_changed_for_each_changed_file' do
    def it_should_call_the_block_for(glob, files)
      params = []
      DoIf.any_file_changed_for_each_changed_file(fixture(glob)) do |f|
        params << f
      end
      params.should =~ files.map {|f| File.expand_path(fixture(f)) }
    end
    
    def it_should_not_call_the_block_at_all(glob)
      was_called = false
      DoIf.any_file_changed_for_each_changed_file(fixture(glob)) do |f|
        was_called = true
      end
      was_called.should == false
    end
    
    describe 'when the specified directory hasnt been run before' do
      it 'should call the block once with the file name' do
        it_should_call_the_block_for('one_file/**/*', ['one_file/1'])
      end
      
      it 'should only the block on each file when multiple files exist' do
        it_should_call_the_block_for('many_files/**/*', ['many_files/1', 'many_files/2'])
      end
    end
    
    describe 'when the specified directory has been run before' do
      before do
        DoIf.any_file_changed_for_each_changed_file(fixture("one_file/**/*")) do end
        DoIf.any_file_changed_for_each_changed_file(fixture("many_files/**/*")) do end
      end
      
      describe 'when no files have changed' do
        it "should not call the block when only a single file exists" do
          it_should_not_call_the_block_at_all('one_file/**/*')
        end
        
        it "should not call the block when many files exist" do
          it_should_not_call_the_block_at_all('many_files/**/*')
        end
      end
      
      describe 'when a file then changes' do
        it 'should call the block for the changed file' do
          touch('one_file/1')
          it_should_call_the_block_for('one_file/**/*', ['one_file/1'])
        end
        
        it 'should not call the block for the unchnaged files' do
          touch('many_files/1')
          it_should_call_the_block_for('many_files/**/*', ['many_files/1'])
        end
      end
      
      describe 'when a file is added' do
        it 'should call the block for the new file' do
          touch('many_files/42')
          it_should_call_the_block_for('many_files/**/*', ['many_files/42'])
        end
      end
      
      describe 'when a file is deleted' do
        it 'should not call the block' do
          FileUtils.rm(fixture('many_files/2'))
          it_should_not_call_the_block_at_all('many_files/**/*')
        end
      end
    end
  end

  describe '.temp_directory' do
    describe 'with the default temp_directory' do
      it 'returns the default' do
        DoIf.temp_directory.should == '/tmp'
      end

      it 'saves the YAML file in the temp_directory' do
        DoIf.any_file_changed(fixture("one_file/**/*")) do end
        File.exists?('/tmp/do_if.yml').should be_true
      end
    end

    describe 'with an overridden temp_directory' do
      before do
        FileUtils.rm_r('/tmp/do_if') if File.exists?('/tmp/do_if')
        DoIf.temp_directory = '/tmp/do_if/test'
        DoIf.any_file_changed(fixture('one_file/**/*')) do end
      end

      it 'creates any necessary directories' do
        File.exists?('/tmp/do_if/test').should be_true
      end

      it 'saves the YAML file in the specified directory' do
        File.exists?('/tmp/do_if/test/do_if.yml').should be_true
      end
    end
  end
end