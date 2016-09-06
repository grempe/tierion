# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tierion/version'

Gem::Specification.new do |spec|
  spec.name          = 'tierion'
  spec.version       = Tierion::VERSION
  spec.authors       = ['Glenn Rempe']
  spec.email         = ['glenn@rempe.us']

  spec.required_ruby_version = '>= 2.1.0'

  cert = File.expand_path('~/.gem-certs/gem-private_key_grempe.pem')
  if cert && File.exist?(cert)
    spec.signing_key = cert
    spec.cert_chain = ['certs/gem-public_cert_grempe.pem']
  end

  spec.summary = <<-EOF
  A simple API client for the Tierion Hash API

  https://tierion.com/docs/hashapi
  EOF

  spec.description = <<-EOF
  A simple API client for the Tierion Hash API

  https://tierion.com/docs/hashapi
  EOF

  spec.homepage      = 'https://github.com/grempe/tierion'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # spec.bindir        = 'exe'
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httparty', '~> 0.13'
  spec.add_runtime_dependency 'activesupport', '>= 4.0'
  spec.add_runtime_dependency 'hashie', '~> 3.4'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.10'
end
