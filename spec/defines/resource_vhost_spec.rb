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
end
