#Find-Module -Name SqlServer | Install-Module -AllowClobber

Import-Module SqlServer 

$dba_main = 'localhost'

Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query 'exec [dbo].[usp_server_configuration_create_tables]'

#$fetch_rs = Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query 'exec [dbo].[usp_fetch_production_registered_servers]'


foreach ($rs in $fetch_rs) { 
    
    #$sqlcon = 'SQLSERVER:\SQL\' + $rs.server_name + '\' + $rs.instance_name + ''
    $sqlcon = 'SQLSERVER:\SQL\localhost\DEFAULT'
    
    $sqlserver = Get-Item $sqlcon
    #$sqlServerName = ($rs.server_name + '\' + $rs.instance_name)

    <#
    $dTotalSize = 0
    #Total Database Disk Size
    foreach ($d in $sqlServer.Databases) {
        $dTotalSize = $d.Size + $dTotalSize
    }
    $dTotalSize = [math]::round($dTotalSize / 1024, 2)
    #>

    #  general
    $name = $sqlServer.Name
    $db_count = $sqlServer.Databases.Count 
    $edition = $sqlserver.Edition
    $version = $sqlserver.Version.ToString()
    $product_level = $sqlServer.ProductLevel
    $procs = $sqlserver.Processors
    $server_memory = [math]::round($sqlServer.PhysicalMemory / 1024)
    $windows_version = $sqlServer.HostPlatform + ' ' + $sqlServer.Platform + ' ' + $sqlServer.OSVersion 

    #  memory
    $min_memory = [math]::round($sqlServer.Configuration.MaxServerMemory.Minimum / 1024)
    $max_memory = [math]::round($sqlServer.Configuration.MaxServerMemory.RunValue / 1024)
    #  security

    $login_mode = $sqlServer.LoginMode
    #  database settings

    $fill_factor = $sqlServer.Configuration.FillFactor.RunValue
    $backup_c = $sqlServer.Configuration.DefaultBackupCompression.RunValue
    $backup_dir = $sqlServer.BackupDirectory
    $log_dir = $sqlServer.DefaultLog
    $root_dir = $sqlServer.RootDirectory
    $data_dir = $sqlServer.InstallDataDirectory
    #  advanced

    $adhoc_q = $sqlServer.Configuration.AdHocDistributedQueriesEnabled.RunValue
    $max_dop = $sqlServer.Configuration.MaxDegreeOfParallelism.RunValue
    $cost_threshold = $sqlServer.Configuration.CostThresholdForParallelism.RunValue
    #  traceflags
    $tflags = $sqlServer.EnumActiveGlobalTraceFlags()

    #  init 
    $has_tflag = 0
    $has_sku = 0
    
    $q = '
        if not exists (
        select server_name from server_configuration_production_group 
        where 
            convert(date, capture_date, 103) = convert(date, getdate(), 103) and 
            server_name = ''' + $name + ''')
        begin
            insert into [server_configuration_production_group] (
                capture_date, server_name, database_count, edition, version, service_pack, processors, physical_memory_gb,
                windows_version, min_server_memory_gb, max_server_memory_gb, login_mode, fill_factor, is_backup_compression, root_directory, backup_directory,
                log_directory, data_directory, is_adhoc_workload, max_dop, cost_threshold, is_trace_flag, is_enterprise_feature
                )
            select getdate(), ''' + $name + ''',''' + $db_count + ''',''' + $edition + ''',''' +  $version + ''',''' + $product_level + ''',''' +  $procs + ''',''' + 
            $server_memory + ''',''' + $windows_version + ''',''' + $min_memory + ''',''' + $max_memory + ''',''' + $login_mode + ''',''' +  $fill_factor + ''',''' +  
            $backup_c + ''',''' + $root_dir + ''',''' + $backup_dir + ''',''' + $log_dir + ''',''' + $data_dir + ''',''' + $adhoc_q + ''',''' + $max_dop + ''',''' +  $cost_threshold + ''',''' + 
            $has_tflag + ''',''' + $has_sku + '''
        end

    '
    Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query $q

    foreach ($t in  $tflags) {
        $q_tflag = '
            update [server_configuration_production_group]
            set
                is_trace_flag = 1
            where server_name = ''' + $name + ''' and convert(date, capture_date, 103) = convert(date, getdate(), 103)
        '
        Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query $q_tflag

        $q_tflag = '
         if not exists (
            select server_name, trace_flag from server_configuration_trace_flag_production_group 
            where 
                convert(date, capture_date, 103) = convert(date, getdate(), 103) and 
                server_name = ''' + $name + ''' and 
                trace_flag = ''' + $t.TraceFlag + ''')
        begin
            insert into [server_configuration_trace_flag_production_group] (capture_date, server_name, trace_flag)
            select getdate(), ''' + $name + ''',''' + $t.TraceFlag + '''
        end
       '
        Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query $q_tflag
    }

    #  instance have any enterprise features?
    foreach($d in $sqlServer.Databases | Where {$_.Name -ne 'master' -and  $_.Name -ne 'model' -and $_.Name -ne 'msdb' -and $_.Name -notlike '*tempdb*' -and $_.Status -eq 'Normal'}) {    
     $q = '
        select  
            serverproperty(''ServerName'') as [sql_instance], 
            isnull(serverproperty(''InstanceName''), ''MSSQLSERVER'') as [instance_name],
            db_name() as [database_name], 
            feature_id as [id],
            feature_name as [feature] 
        from sys.dm_db_persisted_sku_features s
	    inner join sys.databases d on d.name=db_name() and d.state_desc = ''ONLINE''

    '
        
      $q_sku = Invoke-Sqlcmd -ServerInstance $sqlServer.Name -Database $d.Name -Query $q

        foreach($sku in $q_sku) {
          $qInsert = '
            if not exists (
                select server_name, database_name, feature_id, feature_name from server_configuration_sku_production_group 
                where 
                    convert(date, capture_date, 103) = convert(date, getdate(), 103) and 
                    server_name = ''' + $name + ''' and 
                    database_name = ''' + $sku.database_name + ''' and
                    feature_id = ''' + $sku.id + ''' and 
                    feature_name = ''' + $sku.feature + ''')
            begin
                update [server_configuration_production_group] set is_enterprise_feature = 1  where server_name = ''' + $name + ''' and convert(date, capture_date, 103) = convert(date, getdate(), 103)
            
                insert into [server_configuration_sku_production_group] (capture_date, server_name, instance_name, database_name, feature_id, feature_name)
                select getdate(), ''' + $name + ''',''' + $sku.instance_name + ''',''' + $sku.database_name + ''',''' + $sku.id + ''',''' + $sku.feature + '''
            end
          '
        Invoke-Sqlcmd -ServerInstance $dba_main -Database 'DBA' -Query $qInsert
        }
    }
}
