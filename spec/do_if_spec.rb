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
      end
    end
  end
end