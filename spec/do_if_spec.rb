require File.join(File.dirname(__FILE__), '../lib/do_if')

def it_should_call_the_block(fixture_glob)
  it 'should call the block' do
    was_called = false
    DoIf.any_file_changed fixture(fixture_glob) do
      was_called = true
    end
    was_called.should == true
  end
end

def it_should_not_call_the_block(fixture_glob)
  it 'should call the block' do
    was_called = false
    DoIf.any_file_changed fixture(fixture_glob) do
      was_called = true
    end
    was_called.should == false
  end
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
    FileUtils.rm(DoIf::YAML_FILE) if File.exists?(DoIf::YAML_FILE)
    %w(empty many_files one_file).each do |folder|
      `rm -f #{fixture(folder)}/*`
    end
    
    FileUtils.touch(fixture('one_file/1'))
    FileUtils.touch(fixture('many_files/1'))
    FileUtils.touch(fixture('many_files/2'))
  end
  
  describe '.any_file_changed' do
    describe 'when the specified directory hasnt been run before' do
      it_should_call_the_block 'one_file/**/*'
      
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
      end
    end
  end
end