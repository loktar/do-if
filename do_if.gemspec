spec = Gem::Specification.new do |s|
  s.name = "do-if"
  s.version = "1.0"
  s.platform = Gem::Platform::RUBY
  s.date = Time.now.strftime('%Y-%m-%d')
  s.authors = ["Ian Fisher", "Gregg Van Hove"]
  s.email = ["loktar@gmail.com", "gregg@slackersoft.net"]
  s.homepage = "https://github.com/loktar/do-if"
  s.license = "MIT"
  s.has_rdoc = false
  s.summary = ""

  s.add_development_dependency "rspec", "2.2.0"
  s.add_development_dependency "rake"
  
  s.files = `git ls-files`.split("\n")
end