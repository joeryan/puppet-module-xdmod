shared_examples_for "xdmod::config" do

  [
    'logger',
    'database',
    'datawarehouse',
    'shredder',
    'hpcdb',
  ].each do |section|
    it do
      should contain_xdmod_portal_setting("#{section}/host").with({
        :value  => 'localhost',
        :before => [
          'File[/etc/xdmod/hierarchy.csv]',
          'File[/etc/xdmod/group-to-hierarchy.csv]',
          'File[/etc/xdmod/names.csv]',
        ]
      })
    end
    it do
      should contain_xdmod_portal_setting("#{section}/port").with({
        :value  => '3306',
        :before => [
          'File[/etc/xdmod/hierarchy.csv]',
          'File[/etc/xdmod/group-to-hierarchy.csv]',
          'File[/etc/xdmod/names.csv]',
        ]
      })
    end
    it do
      should contain_xdmod_portal_setting("#{section}/user").with({
        :value  => 'xdmod',
        :before => [
          'File[/etc/xdmod/hierarchy.csv]',
          'File[/etc/xdmod/group-to-hierarchy.csv]',
          'File[/etc/xdmod/names.csv]',
        ]
      })
    end
    it do
      should contain_xdmod_portal_setting("#{section}/pass").with({
        :value  => 'changeme',
        :before => [
          'File[/etc/xdmod/hierarchy.csv]',
          'File[/etc/xdmod/group-to-hierarchy.csv]',
          'File[/etc/xdmod/names.csv]',
        ]
      })
    end
  end

  it { should contain_xdmod_portal_setting('features/appkernels').with_value('off') }
  it { should contain_xdmod_portal_setting('reporting/java_path').with_value('/usr/bin/java') }
  it { should_not contain_file('/etc/xdmod/portal_settings.d/appkernels.ini') }
  it { should_not contain_xdmod_appkernel_setting('features/appkernels') }
  it { should_not contain_xdmod_appkernel_setting('appkernel/host') }
  it { should_not contain_xdmod_appkernel_setting('appkernel/port') }
  it { should_not contain_xdmod_appkernel_setting('appkernel/user') }
  it { should_not contain_xdmod_appkernel_setting('appkernel/pass') }
  it { should_not contain_xdmod_appkernel_setting('akrr-db/host') }
  it { should_not contain_xdmod_appkernel_setting('akrr-db/port') }
  it { should_not contain_xdmod_appkernel_setting('akrr-db/user') }
  it { should_not contain_xdmod_appkernel_setting('akrr-db/pass') }
  it { should_not contain_xdmod_appkernel_setting('akrr/host') }
  it { should_not contain_xdmod_appkernel_setting('akrr/port') }
  it { should_not contain_xdmod_appkernel_setting('akrr/username') }
  it { should_not contain_xdmod_appkernel_setting('akrr/password') }

  it do
    should contain_file('/etc/xdmod/portal_settings.ini').with({
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0644',
    })
  end

  it do
    should contain_file('/etc/xdmod/hierarchy.csv').with({
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0644',
      :notify  => 'Exec[xdmod-import-csv-hierarchy]',
    })
  end

  it do
    verify_exact_contents(catalogue, '/etc/xdmod/hierarchy.csv', [])
  end

  it do
    should contain_exec('xdmod-import-csv-hierarchy').with({
      :path        => '/sbin:/bin:/usr/sbin:/usr/bin',
      :command     => 'xdmod-import-csv -t hierarchy -i /etc/xdmod/hierarchy.csv',
      :refreshonly => 'true',
    })
  end

  it do
    should contain_file('/etc/xdmod/group-to-hierarchy.csv').with({
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0644',
      :notify  => 'Exec[xdmod-import-csv-group-to-hierarchy]',
    })
  end

  it do
    verify_exact_contents(catalogue, '/etc/xdmod/group-to-hierarchy.csv', [])
  end

  it do
    should contain_exec('xdmod-import-csv-group-to-hierarchy').with({
      :path        => '/sbin:/bin:/usr/sbin:/usr/bin',
      :command     => 'xdmod-import-csv -t group-to-hierarchy -i /etc/xdmod/group-to-hierarchy.csv',
      :refreshonly => 'true',
    })
  end

  it do
    should contain_file('/etc/xdmod/names.csv').with({
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0644',
      :notify  => 'Exec[xdmod-import-csv-names]',
    })
  end

  it do
    verify_exact_contents(catalogue, '/etc/xdmod/names.csv', [])
  end

  it do
    should contain_exec('xdmod-import-csv-names').with({
      :path        => '/sbin:/bin:/usr/sbin:/usr/bin',
      :command     => 'xdmod-import-csv -t names -i /etc/xdmod/names.csv',
      :refreshonly => 'true',
    })
  end

  it do
    should contain_file('/etc/xdmod/portal_settings.ini').with({
      :ensure  => 'file',
      :owner   => 'root',
      :group   => 'root',
      :mode    => '0644',
    })
  end

  it { should_not contain_file('/root/xdmod-database-setup.sh') }
  it { should_not contain_exec('xdmod-database-setup.sh') }


  it do
    should contain_file('/etc/cron.d/xdmod').with({
      :ensure => 'file',
      :owner  => 'root',
      :group  => 'root',
      :mode   => '0644',
    })
  end

  it do
    verify_contents(catalogue, '/etc/cron.d/xdmod', [
      '# Every morning at 3:00 AM -- run the report scheduler',
      '0 3 * * * root /usr/bin/php /usr/lib/xdmod/report_schedule_manager.php >/dev/null',
      '# Shred and ingest:',
      '0 1 * * * root /usr/bin/xdmod-slurm-helper --quiet -r example && /usr/bin/xdmod-ingestor --quiet',
    ])
  end

  it do
    should contain_logrotate__rule('xdmod').with({
      :ensure        => 'present',
      :path          => '/var/log/xdmod/*.log',
      :rotate        => '4',
      :rotate_every  => 'week',
      :missingok     => 'true',
      :compress      => 'true',
      :dateext       => 'true',
    })
  end

  context 'when database_host => host.domain' do
    let(:params) {{ :database_host => 'host.domain' }}

    it do
      should contain_file('/root/xdmod-database-setup.sh').with({
        :ensure => 'file',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0700',
      })
    end

    #TODO: Test content of /root/xdmod-database-setup.sh

    it do
      should contain_exec('xdmod-database-setup.sh').with({
        :path     => '/usr/bin:/bin:/usr/sbin:/sbin',
        :command  => '/root/xdmod-database-setup.sh && touch /etc/xdmod/.database-setup',
        :creates  => '/etc/xdmod/.database-setup',
      })
    end
  end

  context 'when enable_appkernel => true' do
    let(:params) {{ :enable_appkernel => true }}

    it { should contain_xdmod_portal_setting('features/appkernels').with_value('on') }

    it do
      should contain_file('/etc/xdmod/portal_settings.d/appkernels.ini').with({
        :ensure => 'file',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0644',
      })
    end

    it { should contain_xdmod_appkernel_setting('features/appkernels').with_value('on') }
    it { should contain_xdmod_appkernel_setting('appkernel/host').with_value('localhost') }
    it { should contain_xdmod_appkernel_setting('appkernel/port').with_value('3306') }
    it { should contain_xdmod_appkernel_setting('appkernel/user').with_value('akrr') }
    it { should contain_xdmod_appkernel_setting('appkernel/pass').with_value('changeme') }
    it { should contain_xdmod_appkernel_setting('akrr-db/host').with_value('localhost') }
    it { should contain_xdmod_appkernel_setting('akrr-db/port').with_value('3306') }
    it { should contain_xdmod_appkernel_setting('akrr-db/user').with_value('akrr') }
    it { should contain_xdmod_appkernel_setting('akrr-db/pass').with_value('changeme') }
    it { should contain_xdmod_appkernel_setting('akrr/host').with_value('localhost') }
    it { should contain_xdmod_appkernel_setting('akrr/port').with_value('8091') }
    it { should contain_xdmod_appkernel_setting('akrr/username').with_value('rw') }
    it { should contain_xdmod_appkernel_setting('akrr/password').with_value(/.*/) }
  end

  context 'when hierarchies defined' do
    let(:params) do
      {
        :hierarchies => [
          'ou1,Unit 1,',
          '"ou2","Unit 2",""',
          'div1,Division 1,ou1',
          '"div2","Division 2","ou2"',
          'dept1,Department 1,div1',
          '"dept2","Department 2","div2"',
        ]
      }
    end

    it do
      verify_exact_contents(catalogue, '/etc/xdmod/hierarchy.csv', [
        '"ou1","Unit 1",""',
        '"ou2","Unit 2",""',
        '"div1","Division 1","ou1"',
        '"div2","Division 2","ou2"',
        '"dept1","Department 1","div1"',
        '"dept2","Department 2","div2"',
      ])
    end
  end

  context 'when group_to_hierarchy defined' do
    let(:params) do
      {
        :group_to_hierarchy => {
          'group1' => 'dept1',
          'group2' => 'dept1',
          'group3' => 'dept2',
        }
      }
    end

    it do
      verify_exact_contents(catalogue, '/etc/xdmod/group-to-hierarchy.csv', [
        '"group1","dept1"',
        '"group2","dept1"',
        '"group3","dept2"',
      ])
    end
  end

  context 'when user_pi_names defined' do
    let(:params) do
      {
        :user_pi_names => [
          'jdoe,John,Doe',
          'mygroup,,"My Group"',
        ]
      }
    end

    it do
      verify_exact_contents(catalogue, '/etc/xdmod/names.csv', [
        'jdoe,John,Doe',
        'mygroup,,"My Group"',
      ])
    end
  end
end
