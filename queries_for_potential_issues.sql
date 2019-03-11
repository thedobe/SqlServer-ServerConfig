-- needs patching immediately
select server_name, edition, version, service_pack
from server_configuration_production_group
where service_pack = 'RTM'
and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- needs memory adjusted
select server_name, physical_memory_gb, 
cast(
	iif(len(physical_memory_gb) = '2', 
		physical_memory_gb *.75, 
		left(physical_memory_gb *.70,1)
	) * 1024 as int
)  as recommended_mb
from server_configuration_production_group
where max_server_memory_gb > physical_memory_gb 
and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- if SQL2012 and 4199 is not enabled, strongly consider enabling it 
select s.server_name, s.is_trace_flag
from server_configuration_production_group s
left join (select top 1 server_name from server_configuration_trace_flag_production_group where trace_flag <> '4199' group by server_name) t on t.server_name = s.server_name
where 
(left([version],2) = '11' and s.is_trace_flag = 0) or (left([version],2) = '11' and t.server_name is null)
and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- Enterprise Edition, but, not using any features; strongly consider downgrading
select server_name, edition, version, service_pack, is_enterprise_feature
from server_configuration_production_group
where edition like 'Enterprise%' and is_enterprise_feature = 0
--and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- Cost Threshold too low, increase to at least 35 (will not require service restart)
select server_name, edition, version, service_pack, cost_threshold
from server_configuration_production_group
where cost_threshold <= 35
and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- MAX DOP may be incorrectly configured (all cores) (will not require a restart)
select server_name, edition, version, service_pack, processors, max_dop
from server_configuration_production_group
where max_dop = 0
union all 
select server_name, edition, version, service_pack, processors, max_dop
from server_configuration_production_group
where max_dop <> 0 and (
	processors / max_dop = 1
)
and convert(date, capture_date, 103) = convert(date, getdate(), 103)



-- Servers are older than 2012 and should upgraded or documented
select server_name, edition, version, service_pack
from server_configuration_production_group
where left([version],2) < '11'
and convert(date, capture_date, 103) = convert(date, getdate(), 103)


/*
--adhoc randomness
select * from server_configuration_production_group where server_name = ''

delete from server_configuration_production_group
where convert(date, capture_date, 103) = convert(date, getdate(), 103)
*/
