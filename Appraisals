case(RUBY_VERSION)

  when '2.0.0', '2.1.2' then
    appraise "ruby-#{RUBY_VERSION}_rails32" do
      gem "rails",    '3.2.17'

    end

  else
    raise "Unsupported Rails version #{RUBY_VERSION}"

end
