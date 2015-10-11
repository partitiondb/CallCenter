use master;
begin
declare @sql nvarchar(max);
select @sql = coalesce(@sql,'') + 'kill ' + convert(varchar, spid) + ';'
from master..sysprocesses
where dbid in (db_id('CallGate'),db_id('AnyTradeDB'),db_id('BestTradeDB'),db_id('GoTradeDB'),db_id('CallGlobalDB'),db_id('CallCommonDB'),db_id('RepCallGate'),db_id('RepAnyTradeDB'),db_id('RepBestTradeDB'),db_id('RepGoTradeDB'),db_id('RepCallGlobalDB'),db_id('RepCallCommonDB')) and cmd = 'AWAITING COMMAND' and spid <> @@spid;
exec(@sql);
end;
go
if db_id('CallGate') 		is not null drop database CallGate;
if db_id('AnyTradeDB') 		is not null drop database AnyTradeDB;
if db_id('BestTradeDB')  	is not null drop database BestTradeDB;
if db_id('GoTradeDB') 		is not null drop database GoTradeDB;
if db_id('CallGlobalDB') 	is not null drop database CallGlobalDB;
if db_id('CallCommonDB') 	is not null drop database CallCommonDB;
if db_id('RepCallGate') 	is not null drop database RepCallGate;
if db_id('RepAnyTradeDB') 	is not null drop database RepAnyTradeDB;
if db_id('RepBestTradeDB')  is not null drop database RepBestTradeDB;
if db_id('RepGoTradeDB') 	is not null drop database RepGoTradeDB;
if db_id('RepCallGlobalDB') is not null drop database RepCallGlobalDB;
if db_id('RepCallCommonDB') is not null drop database RepCallCommonDB;
create database AnyTradeDB;
create database BestTradeDB;
create database GoTradeDB;
create database CallGlobalDB;
create database CallCommonDB;
create database RepAnyTradeDB;
create database RepBestTradeDB;
create database RepGoTradeDB;
create database RepCallGlobalDB;
create database RepCallCommonDB;
use PdbLogic;
exec Pdbinstall 'CallGate',@ColumnName='CallCenterId';
exec Pdbinstall 'RepCallGate',@ColumnName='CallCenterId',@ProductTypeId=2;
go
use CallGate;
exec PdbcreatePartition 'CallGate','AnyTradeDB',1;
exec PdbcreatePartition 'CallGate','BestTradeDB',2;
exec PdbcreatePartition 'CallGate','GoTradeDB',3;
exec PdbcreatePartition 'CallGate','CallGlobalDB',@DatabaseTypeId=3;
exec PdbcreatePartition 'CallGate','CallCommonDB',@DatabaseTypeId=2;

create table CallCenters
	(	Id 					PartitionDBType			not null primary key
	,	CallCenterNumber	nvarchar(16)			not null unique
	,	Name				nvarchar(128)			not null unique
	,	URL					nvarchar(256)
	,	Company				nvarchar(128)
	);

create table Topics
	(	Id  				tinyint identity(1,1) 	not null primary key
	,	Subject				nvarchar(128)			not null unique
	);
	
create table Customers
	(	CallCenterId		PartitionDBType		 	not null references CallCenters (Id)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(256)			not null unique
	,	PhoneNumber			nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	);

create table Departments
	(	Id  				tinyint				 	not null primary key
	,	Name				nvarchar(128)			not null unique
	);

create table Employees
	(	CallCenterId		PartitionDBType		 	not null references CallCenters (Id)
	,	Id  				smallint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(256)			not null unique
	,	DepartmentId		tinyint					not null references Departments (Id)
	,	ManagerEmployeeId	smallint				
	);

alter table Employees add foreign key (ManagerEmployeeId) references Employees (Id)

create table Calls
	(	CallCenterId		PartitionDBType		 	not null references CallCenters (Id)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	CustomerId			bigint					not null references Customers (Id)
	,	TopicId				tinyint					not null references Topics (Id)
	,	Description			nvarchar(500)			not null
	);

create table Comments
	(	CallCenterId		PartitionDBType		 	not null references CallCenters (Id)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	CallId				bigint					not null references Calls (Id)
	,	EmployeeId			smallint				not null references Employees (Id)
	,	Description			nvarchar(256)			not null
	);

create table Tasks
	(	CallCenterId		PartitionDBType		 	not null references CallCenters (Id)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	EmployeeId			smallint				not null references Employees (Id)
	,	CallId				bigint					not null references Calls (Id)
	,	Status				tinyint
	,	Description			nvarchar(500)
	);

create index CallCenters_01_IX on CallCenters (Company);	
create index Customers_01_IX on Customers (FirstName,LastName);	
create index Employees_01_IX on Employees (DepartmentId,ManagerEmployeeId);	
create index Employees_02_IX on Employees (FirstName,LastName);	
create index Calls_01_IX on Calls (CustomerId);
create index Calls_02_IX on Calls (TopicId);
create index Comments_01_IX on Comments (CallId,EmployeeId);
create index Comments_02_IX on Comments (EmployeeId);
create index Tasks_01_IX on Tasks (EmployeeId,CallId);
create index Tasks_02_IX on Tasks (CallId);
create index Tasks_03_IX on Tasks (Status,EmployeeId);

insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (1,'001','Any Trade','http://www.partitiondb.com/anytrade/','Any Trade Ltd');
insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (2,'002','Best Trade','http://www.partitiondb.com/besttrade/','Best Trade Ltd');
insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (3,'003','Go Trade','http://www.partitiondb.com/gotrade/','Go Trade Ltd');
insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (4,'004','High Trade','http://www.partitiondb.com/hightrade/','High Trade Ltd');
insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (5,'005','One Trade','http://www.partitiondb.com/onetrade/','One Trade Ltd');
insert into PdbCallCenters (Id,CallCenterNumber,Name,URL,Company) values (6,'006','Top Trade','http://www.partitiondb.com/toptrade/','Top Trade Ltd');
	
insert into PdbTopics (Subject) values ('General');
insert into PdbTopics (Subject) values ('Problem');
insert into PdbTopics (Subject) values ('Strategy');
insert into PdbTopics (Subject) values ('Trading');
insert into PdbTopics (Subject) values ('Tips & Tricks');
	
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Jimi','Hendrix','jimi.hendrix@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Robert','Johnson','robert.johnson@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Albert','King','albert.king@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'BB','King','bb.king@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Buddy','Guy','buddy.guy@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Hubert','Sumlin','hubert.sumlin@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Chuck','Berry','chuck.berry@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Johnny','Winter','johnny.winter@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Ry','Cooder','ry.cooder@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Keith','Richards','keith.richards@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'John','Frusciante','john.frusciante@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Jeff','Beck','jeff.beck@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Jimi','Page','jimi.page@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Richard','Thompson','richard.thompson@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Stevie','Vaughan','stevie.vaughan@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Eric','Clapton','eric.clapton@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'The','Edge','the.edge@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Brian','May','brian.may@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Van','Halen','van.halen@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Frank','Zappa','frank.zappa@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Joe','Perry','joe.perry@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Ritchie','Blackmore','ritchie.blackmore@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Steve','Howe','steve.howe@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'David','Gilmour','david.gilmour@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Rhandy','Roads','rhandy.roads@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Angus','Young','angus.young@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Mark','Knopfler','mark.knopfler@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Peter','Green','peter.green@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Lindsey','Buckingham','lindsey.buckingham@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (1,'Gary','Moore','gary.moore@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Chet','Atkins','chet.atkins@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Andy','Summers','andy.summers@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Carlos','Santana','carlos.santana@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Peter','Frampton','peter.frampton@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Pete','Townshend','pete.townshend@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Robbie','Krieger','robbie.krieger@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'George','Harrison','george.harrison@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Neil','Young','neil.young@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Albert','Collins','albert.collins@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Rory','Gallagher','rory.gallagher@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Jeff','Healey','jeff.healey@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Lightnin','Hopkins','lightnin.hopkins@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Bo','Didley','bo.didley@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Joe','Walsh','joe.walsh@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Vernon','Reid','vernon.reid@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Kurt','Cobain','kurt.cobain@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Duane','Allman','duane.allman@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Joe','Satriani','joe.satriani@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Steve','Vai','steve.vai@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Yngwie','Malmsteen','yngwie.malmsteen@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Paul','Gilbert','paul.gilbert@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Eric','Johnson','eric.johnson@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Steve','Morse','steve.morse@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Nuno','Bettencourt','nuno.bettencourt@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Kirk','Hammet','kirk.hammet@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'James','Hetfield','james.hetfield@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Dave','Mustain','dave.mustain@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Marty','Friedman','marty.friedman@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'John','Petrucci','john.petrucci@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (2,'Alex','Lifeson','alex.lifeson@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'DimeBag','Darrel','dimebag.darrel@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'George','Lynch','george.lynch@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Vinnie','Moore','vinnie.moore@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Paco','DeLucia','paco.delucia@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Adrian','Legg','adrian.legg@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Tommy','Emmanuel','tommy.emmanuel@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Paco','Pena','paco.pena@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Roy','Buchanan','roy.buchanan@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Michael','Schenker','michael.schenker@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Johnny','Ramone','johnny.ramone@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Tom','Morello','tom.morello@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Adam','Jones','adam.jones@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Brad','Paisley','brad.paisley@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Jason','Becker','jason.becker@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Joe','Bonamassa','joe.bonamassa@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Albert','Lee','albert.lee@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'John','Lennon','john.lennon@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Paul','McCartney','paul.mccartney@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Steve','Lukather','steve.lukather@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Hank','Marvin','hank.marvin@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Dave','Matthews','dave.matthews@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Mike','McCready','mike.mccready@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Richie','Sambora','richie.sambora@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Keith','Scott','keith.scott@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Scotty','Moore','scotty.moore@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Brian','Setzer','brian.setzer@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Phil','Collen','phil.collen@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Robert','Cray','robert.cray@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Robert','Fripp','robert.fripp@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (3,'Danny','Gatton','danny.gatton@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Mike','Bloomfield','mike.bloomfield@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'John','Fahey','john.fahey@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Tony','Iommi','tony.iommi@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Richie','Kotzen','richie.kotzen@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Shawn','Lane','shawn.lane@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Alex','Skolnick','alex.skolnick@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Jeff','Waters','jeff.waters@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Dave','Grohl','dave.grohl@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Jeff','Hanneman','jeff.hanneman@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (4,'Jennifer','Batten','jennifer.batten@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Guthrie','Govan','guthrie.govan@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Andy','Mckee','andy.mckee@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'John','Mayer','john.mayer@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Gary','Hoey','gary.hoey@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Matthew','Bellamy','matthew.bellamy@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Noel','Gallagher','noel.gallagher@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Jerry','Garcia','jerry.garcia@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Jonny','Greenwood','jonny.greenwood@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'George','Lynch','george.lynch@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (5,'Daron','Malakian','daron.malakian@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'James','Burton','james.burton@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Warren','Haynes','warren.haynes@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Dick','Dale','dick.dale@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Jorma','Kaukonen','jorma.kaukonen@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Mick','Ronson','mick.ronson@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Freddie','King','freddie.king@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Trey','Anastasio','trey.anastasio@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Greg','Howe','greg.howe@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Andy','Timmons','andy.timmons@partitiondb.com');
insert into PdbCustomers (CallCenterId,FirstName,LastName,EMail) values (6,'Tony','Macalpine','tony.macalpine@partitiondb.com');

insert into PdbDepartments (Id,Name) values (1,'Sales');
insert into PdbDepartments (Id,Name) values (2,'Enginneering');

insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Sebastian','Vettel','sebastian.vettel@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Fernando','Alonso','fernando.alonso@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Lewis','Hamilton','lewis.hamilton@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Michael','Schumacher','michael.schumacher@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Jenson','Button','jenson.button@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Kimi','Raikkonen','kimi.raikkonen@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Nico','Rosberg','nico.rosberg@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Mark','Webber','mark.webber@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Felipe','Massa','felipe.massa@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Alain','Prost','alain.prost@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Rubens','Barrichello','rubens.barrichello@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Ayrton','Senna','ayrton.senna@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'David','Coulthard','david.coulthard@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Nelson','Piquet','nelson.piquet@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Nigel','Mansell','nigel.mansell@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Niki','Lauda','niki.lauda@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Gerhard','Berger','gerhard.berger@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Jackie','Stewart','jackie.stewart@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Damon','Hill','damon.hill@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (1,'Daniel','Ricciardo','daniel.ricciardo@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 1 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Ralf','Schumacher','ralf.schumacher@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Carlos','Reutemann','carlos.reutemann@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Valtteri','Bottas','valtteri.bottas@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Graham','Hill','graham.hill@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Emerson','Fittipaldi','emerson.fittipaldi@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Riccardo','Patrese','riccardo.patrese@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Giancarlo','Fisichella','giancarlo.fisichella@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jim','Clark','jim.clark@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Romain','Grosjean','romain.grosjean@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Robert','Kubica','robert.kubica@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Nico','Hulkenberg','nico.hulkenberg@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jack','Brabham','jack.brabham@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Nick','Heidfeld','nick.heidfeld@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jody','Scheckter','jody.scheckter@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Denny','Hulme','denny.hulme@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jarno','Trulli','jarno.trulli@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jean','Alesi','jean.alesi@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Jacques','Laffite','jacques.laffite@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Sergio','Perez','sergio.perez@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (2,'Clay','Regazzoni','clay.regazzoni@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 2 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Alan','Jones','alan.jones@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Ronnie','Peterson','ronnie.peterson@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Bruce','McLaren','bruce.mclaren@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Eddie','Irvine','eddie.irvine@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Stirling','Moss','stirling.moss@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Michele','Alboreto','michele.alboreto@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Jacky','Ickx','jacky.ickx@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Rene','Arnoux','rene.arnoux@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'John','Surtees','john.surtees@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Mario','Andretti','mario.andretti@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'James','Hunt','james.hunt@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'John','Watson','john.watson@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Keke','Rosberg','keke.rosberg@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Patrick','Depailler','patrick.depailler@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Alberto','Ascari','alberto.ascari@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Dan','Gurney','dan.gurney@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Thierry','Boutsen','thierry.boutsen@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Mike','Hawthorn','mike.hawthorn@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Nino','Farina','nino.farina@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (3,'Kamui','Kobayashi','kamui.kobayashi@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 3 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Adrian','Sutil','adrian.sutil@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Jochen','Rindt','jochen.rindt@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Richie','Ginther','richie.ginther@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Gilles','Villeneuve','gilles.villeneuve@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Heikki','Kovalainen','heikki.kovalainen@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Patrick','Tambay','patrick.tambay@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Didier','Pironi','didier.pironi@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Phil','Hill','phil.hill@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Martin','Brundle','martin.brundle@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (4,'Johnny','Herbert','johnny.herbert@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 4 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Francois','Cevert','francois.cevert@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Stefan','Johansson','stefan.johansson@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Chris','Amon','chris.amon@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Jean-Pierre','Beltoise','jean-pierre.beltoise@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Olivier','Panis','olivier.panis@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Tony','Brooks','tony.brooks@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Maurice','Trintignant','maurice.trintignant@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Pedro','Rodríguez','pedro.rodríguez@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Jochen','Mass','jochen.mass@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (5,'Derek','Warwick','derek.warwick@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 5 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Eddie','Cheever','eddie.cheever@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Daniil','Kvyat','daniil.kvyat@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Alessandro','Nannini','alessandro.nannini@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Vitaly','Petrov','vitaly.petrov@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Peter','Revson','peter.revson@partitiondb.com',1,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 1 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Pastor','Maldonado','pastor.maldonado@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Andrea','de Cesaris','andrea.de cesaris@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Lorenzo','Bandini','lorenzo.bandini@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Carlos','Pace','carlos.pace@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 2 and ManagerEmployeeId is null));
insert into PdbEmployees (CallCenterId,FirstName,LastName,EMail,DepartmentId,ManagerEmployeeId) values (6,'Kevin','Magnussen','kevin.magnussen@partitiondb.com',2,(select Id from PdbEmployees where CallCenterId = 6 and DepartmentId = 2 and ManagerEmployeeId is null));

if object_id('GetEmployees','P') is not null drop procedure GetEmployees
go 
create procedure GetEmployees-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

if object_id('GetEmployeesPU','P') is not null drop procedure GetEmployeesPU
go 
create procedure GetEmployeesPU-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

if object_id('GetEmployeesPE','P') is not null drop procedure GetEmployeesPE
go 
create procedure GetEmployeesPE-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

exec GetEmployeesPU;
exec PdbGetEmployeesPU;
exec GetEmployeesPU null,1;
exec PdbGetEmployeesPU 1;

/*
if object_id('getCustomerHistory','P') is not null drop procedure getCustomerHistory
go 
create procedure GetCustomerCalls-- 
	(	@CustomerEMail nvarchar(128)
	)
as
begin
	declare @CallCenterId 	tinyint;
	declare @CustomerId		int;
	
	select @CallCenterId = Customers.CallCenterId,@CustomerId = Customers.Id
	from PdbCustomers Customers
	where Customers.EMail = @CustomerEMail;
	
	select Calls.Id CallId,Topics.Subject,Calls.Description
	from PdbCalls Calls
	join PdbTopics Topics on Calls.CallCenterId = Topics.CallCenterId and Calls.TopicId = Topics.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
	
	select Calls.Id CallId,Comments.Id CommentId,Employees.FirstName,Employees.LastName,Comments.Description
	from PdbCalls Calls
	join PdbComments Comments on Calls.CallCenterId = Comments.CallCenterId and Calls.Id = Comments.CallId
	join PdbEmployees Employees on Comments.CallCenterId = Employees.CallCenterId and Comments.EmployeeId = Employees.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
	
	select Calls.Id CallId,Tasks.Id TaskId,Employees.FirstName,Employees.LastName,Tasks.Description,Tasks.Status
	from PdbCalls Calls
	join PdbTasks Tasks on Calls.CallCenterId = Tasks.CallCenterId and Calls.Id = Tasks.CallId
	join PdbEmployees Employees on Tasks.CallCenterId = Employees.CallCenterId and Tasks.EmployeeId = Employees.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
end;
go

if object_id('GetCustomerCallsPU','P') is not null drop procedure GetCustomerCallsPU
go 
create procedure GetCustomerCallsPU-- 
	(	@CallCenterId 	tinyint
	,	@CustomerEMail 	nvarchar(128)
	)
as
begin
	declare @CustomerId		int;
	
	select @CustomerId = Customers.Id
	from Customers
	where Customers.EMail = @CustomerEMail;
	
	select Calls.Id CallId,Topics.Subject,Calls.Description
	from Calls
	join Topics on Calls.CallCenterId = Topics.CallCenterId and Calls.TopicId = Topics.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
	
	select Calls.Id CallId,Comments.Id CommentId,Employees.FirstName,Employees.LastName,Comments.Description
	from Calls
	join Comments on Calls.CallCenterId = Comments.CallCenterId and Calls.Id = Comments.CallId
	join Employees on Comments.CallCenterId = Employees.CallCenterId and Comments.EmployeeId = Employees.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
	
	select Calls.Id CallId,Tasks.Id TaskId,Employees.FirstName,Employees.LastName,Tasks.Description,Tasks.Status
	from Calls
	join Tasks on Calls.CallCenterId = Tasks.CallCenterId and Calls.Id = Tasks.CallId
	join Employees on Tasks.CallCenterId = Employees.CallCenterId and Tasks.EmployeeId = Employees.Id
	where Calls.CallCenterId = @CallCenterId
	  and Calls.CustomerId = @CustomerId;
end;
go

exec GetCustomerCalls 'jimi.hendrix@partitiondb.com';
exec GetCustomerCalls 1,'jimi.hendrix@partitiondb.com';
exec PdbGetCustomerCalls 1,'jimi.hendrix@partitiondb.com';
*/

use RepCallGate;
exec PdbcreatePartition 'RepCallGate','RepAnyTradeDB',1;
exec PdbcreatePartition 'RepCallGate','RepBestTradeDB',2;
exec PdbcreatePartition 'RepCallGate','RepGoTradeDB',3;
exec PdbcreatePartition 'RepCallGate','RepCallGlobalDB',@DatabaseTypeId=3;
exec PdbcreatePartition 'RepCallGate','RepCallCommonDB',@DatabaseTypeId=2;

exec PdbsyncSourceTable 'RepCallGate','dbo','CallCenters','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Topics','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Customers','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Departments','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Employees','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Calls','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Comments','CallGate';
exec PdbsyncSourceTable 'RepCallGate','dbo','Tasks','CallGate';

create index CallCenters_01_IX on CallCenters (Company);	
create index Customers_01_IX on Customers (FirstName,LastName);	
create index Employees_02_IX on Employees (FirstName,LastName);	
create index Calls_02_IX on Calls (TopicId);
create index Comments_02_IX on Comments (EmployeeId);
create index Tasks_03_IX on Tasks (Status,EmployeeId);


if object_id('GetEmployees','P') is not null drop procedure GetEmployees
go 
create procedure GetEmployees-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

if object_id('GetEmployeesPU','P') is not null drop procedure GetEmployeesPU
go 
create procedure GetEmployeesPU-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

if object_id('GetEmployeesPE','P') is not null drop procedure GetEmployeesPE
go 
create procedure GetEmployeesPE-- 
	(	@CallCenterId tinyint = null
	,	@DepartmentId tinyint = null
	)
as
begin
	select CallCenters.Company,Employees.Id EmployeeId,Employees.FirstName,Employees.LastName,ManagerEmployees.FirstName ManagerFirstName,ManagerEmployees.LastName ManagerLastName
	from PdbEmployees Employees 
	join PdbCallCenters CallCenters on Employees.CallCenterId = CallCenters.Id
	left join PdbEmployees ManagerEmployees on Employees.CallCenterId = ManagerEmployees.CallCenterId and Employees.ManagerEmployeeId = ManagerEmployees.Id
	where (@CallCenterId is null or Employees.CallCenterId = @CallCenterId)
	  and (@DepartmentId is null or Employees.DepartmentId = @DepartmentId);
end;
go

exec GetEmployeesPU;
exec GetEmployeesPU null,1;
exec PdbGetEmployeesPU 1;
