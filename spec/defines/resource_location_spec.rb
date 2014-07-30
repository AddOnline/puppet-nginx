require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'nginx::resource::location', :type => :define do

  let(:facts) { {
    :operatingsystem => 'Debian' ,
    :concat_basedir  => '/var/lib/puppet/concat',
  } }
  let(:title) { 'www.example42.com-location' }
  let(:node) { 'rspec.example42.com' }

  describe 'Test to inject custom options' do
    let(:params) { {
      :location => '/example42',
      :www_root => '/var/www/www.example42.com',
      :option   => { 'example' => '42', 'elpmaxe' => '24' },
      :vhost    => 'www.example42.com',
    } }
    it { should contain_concat__fragment('www.example42.com+50-/example42.tmp').with_content(/example\s+42;/) }
    it { should contain_concat__fragment('www.example42.com+50-/example42.tmp').with_content(/elpmaxe\s+24;/) }
  end

  describe 'Test adding proxy header' do
    let(:params) { {
      :location         => '/example42',
      :vhost            => 'www.example42.com',
      :proxy            => 'http://example42.com:4242',
      :proxy_set_header => ['example','42'],
    } }
    it { should contain_concat__fragment('www.example42.com+50-/example42.tmp').with_content(/proxy_set_header\s+example;/) }
    it { should contain_concat__fragment('www.example42.com+50-/example42.tmp').with_content(/proxy_set_header\s+42;/) }
  end

  describe 'Test adding ssl proxy header' do
    let(:params) { {
      :location             => '/example42',
      :vhost                => 'www.example42.com',
      :ssl                  => 'present',
      :mixin_ssl            => true,
      :proxy                => 'http://example42.com:4242',
      :proxy_ssl_set_header => ['example','42'],
    } }
    it { should contain_concat__fragment('www.example42.com+80-ssl-/example42.tmp').with_content(/proxy_set_header\s+example;/) }
    it { should contain_concat__fragment('www.example42.com+80-ssl-/example42.tmp').with_content(/proxy_set_header\s+42;/) }
  end

  describe 'Test simple proxy header is alway present in ssl' do
    let(:params) { {
      :location         => '/example42',
      :vhost            => 'www.example42.com',
      :ssl              => 'present',
      :mixin_ssl        => true,
      :proxy            => 'http://example42.com:4242',
      :proxy_set_header => ['example','42'],
    } }
    it { should contain_concat__fragment('www.example42.com+80-ssl-/example42.tmp').with_content(/proxy_set_header\s+example;/) }
    it { should contain_concat__fragment('www.example42.com+80-ssl-/example42.tmp').with_content(/proxy_set_header\s+42;/) }
  end
end
