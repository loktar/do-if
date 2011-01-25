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

describe DoIf do
  before do
    FileUtils.rm(DoIf::YAML_FILE) if File.exists?(DoIf::YAML_FILE)
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
          FileUtils.touch(fixture('one_file/1'))
        end
        
        it_should_call_the_block 'one_file/**/*'
      end

      describe 'when a file has been added since the last run' do
        before do
          FileUtils.touch(fixture('many_files/42'))
        end
        
        after do
          FileUtils.rm(fixture('many_files/42'))
        end
        
        it_should_call_the_block 'many_files/**/*'
      end
      
      describe 'when a file has been deleted since the last run' do
        before do
          FileUtils.touch(fixture('many_files/42'))
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
            FileUtils.touch(fixture('one_file/1'))
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
      params.length.should == files.length
      files.each_with_index do |file_path, i|
        params[i].should == File.expand_path(fixture(file_path))
      end
    end
    
    describe 'when the specified directory hasnt been run before' do
      it 'should call the block once with the file name' do
        it_should_call_the_block_for('one_file/**/*', ['one_file/1'])
      end
      
      it 'should only the block on each file when multiple files exist' do
        it_should_call_the_block_for('many_files/**/*', ['many_files/1', 'many_files/2'])
      end
    end
  end
end