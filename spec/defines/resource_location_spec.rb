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
end
