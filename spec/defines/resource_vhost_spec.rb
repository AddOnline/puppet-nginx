require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'nginx::resource::vhost', :type => :define do

  let(:facts) { {
    :operatingsystem => 'Debian' ,
    :concat_basedir  => '/var/lib/puppet/concat',
  } }
  let(:title) { 'www.example42.com' }
  let(:node) { 'rspec.example42.com' }

  describe 'Test standard usage creation' do
    let(:params) { {
      :www_root => '/var/www/www.example42.com',
    } }
    it { should contain_file('/etc/nginx/sites-enabled/www.example42.com.conf').with_ensure('link') }
  end

  describe 'Test to deny some path' do
    let(:params) { {
      :www_root        => '/var/www/www.example42.com',
      :denied_location => ['/var','/app'],
    } }
    it { should contain_concat__fragment('www.example42.com+01.tmp').with_content(/location\s+\/var\s+{\s+deny\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+01.tmp').with_content(/location\s+\/app\s+{\s+deny\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+70-ssl.tmp').with_content(/location\s+\/var\s+{\s+deny\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+70-ssl.tmp').with_content(/location\s+\/app\s+{\s+deny\s+all;\s+}/) }
  end

  describe 'Test to allow some path' do
    let(:params) { {
      :www_root        => '/var/www/www.example42.com',
      :allowed_location => ['/var','/app'],
    } }
    it { should contain_concat__fragment('www.example42.com+01.tmp').with_content(/location\s+\/var\s+{\s+allow\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+01.tmp').with_content(/location\s+\/app\s+{\s+allow\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+70-ssl.tmp').with_content(/location\s+\/var\s+{\s+allow\s+all;\s+}/) }
    it { should contain_concat__fragment('www.example42.com+70-ssl.tmp').with_content(/location\s+\/app\s+{\s+allow\s+all;\s+}/) }
  end

  describe 'Test adding proxy header' do
    let(:params) { {
      :proxy            => 'http://example42.com:4242',
      :proxy_set_header => ['example','42'],
    } }
    it { should contain_nginx__resource__location('www.example42.com-default').with_proxy_set_header(['example','42']) }
  end

  describe 'Test adding ssl proxy header' do
    let(:params) { {
      :proxy                => 'http://example42.com:4242',
      :proxy_ssl_set_header => ['example','42'],
      :ssl                  => 'present',
      :ssl_key               => '/example42.key',
      :ssl_cert              => '/example42.crt',
    } }
    it { should contain_nginx__resource__location('www.example42.com-default').with_proxy_ssl_set_header(['example','42']) }
  end

  describe 'Test default ssl proxy template' do
    let(:params) { {
      :proxy                => 'http://example42.com:4242',
      :ssl                  => 'present',
      :ssl_key               => '/example42.key',
      :ssl_cert              => '/example42.crt',
    } }
    it { should contain_nginx__resource__location('www.example42.com-default').with_template_ssl_proxy('nginx/vhost/vhost_location_ssl_proxy.erb') }
  end
end
