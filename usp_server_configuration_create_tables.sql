USE []
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author: <Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_server_configuration_create_tables]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if not exists (select [name] from sys.tables where [name] = 'server_configuration_production_group')
		create table [dbo].[server_configuration_production_group] (
			[id] [int] identity(1,1) NOT NULL,
			[capture_date] [datetime] default getdate() NOT NULL,
			[server_name] [sysname] NULL,
			[database_count] [int] NULL,
			[edition] [varchar](255) NULL,
			[version] [varchar](50) NULL,
			[service_pack] [varchar](10) NULL,
			[processors] [tinyint] NULL,
			[physical_memory_gb] [int] NULL,
			[windows_version] [varchar](250) NULL,
			[min_server_memory_gb] [int] NULL,
			[max_server_memory_gb] [int] NULL,
			[login_mode] [varchar](50) NULL,
			[fill_factor] [tinyint] NULL,
			[is_backup_compression] [bit] NULL,
			[root_directory] [varchar](1000) NULL,
			[backup_directory] [varchar](1000) NULL,
			[log_directory] [varchar](1000) NULL,
			[data_directory] [varchar](1000) NULL,
			[is_adhoc_workload] [bit] NULL,
			[max_dop] [tinyint] NULL,
			[cost_threshold] [tinyint] NULL,
			[is_trace_flag] [varchar](1000) NULL,
			[is_enterprise_feature] [bit] NULL,
			primary key clustered ([id] asc) 
	)

	if not exists (select [name] from sys.tables where [name] = 'server_configuration_trace_flag_production_group')
		create table [dbo].[server_configuration_trace_flag_production_group] (
			[id] [int] identity(1,1) NOT NULL,
			[capture_date] [datetime] default getdate() NOT NULL,
			[server_name] [sysname] NULL,
			[trace_flag] [int]
			primary key clustered ([id] asc) 
	)

	if not exists (select [name] from sys.tables where [name] = 'server_configuration_sku_production_group')
		create table [dbo].[server_configuration_sku_production_group] (
			[id] [int] identity(1,1) NOT NULL,
			[capture_date] [datetime] default getdate() NOT NULL,
			[server_name] [sysname] NULL,
			[instance_name] [sysname] NULL,
			[database_name] [sysname] NULL,
			[feature_id] [varchar](25) NULL,
			[feature_name] [varchar](250) NULL
			primary key clustered ([id] asc) 
	)
END
