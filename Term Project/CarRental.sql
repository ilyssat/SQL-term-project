/* 
Term Project: RentalCar Database
Use Case: Reserve a rental car for a specific period
*/

/* Create Database & Tables */
create database RentalCar;
go

use RentalCar;
go

/* Table 1: Car */
create table Car (
	CarId int not null primary key,
	Make varchar(50) not null,
	Model varchar(50) not null,
	Year int not null,
	SeatingCapacity int not null
	);
	

/* Table 2: AvailabilityCalendar */
create table AvailabilityCalendar (
	AvailabilityCalendarId int not null identity(1,1) primary key,
	Date date not null,
	CarId int not null,
	IsAvailable bit not null default 1, /* 1 = yes, 0 = no */
	constraint FK_AvailabilityCalendar_Car foreign key (CarId) References Car(CarId)
	);
	

/* Table 3: ReservationDetails */
create table ReservationDetails (
	ReservationDetailId int not null identity(1,1) primary key,
	CarId int not null,
	ReservationStartDate date not null,
	ReservationEndDate date not null,
	constraint FK_ReservationDetails_Car foreign key (CarId) references Car(CarId)
	);

go

/* Populate Data */

/* Insert 3 cars */
insert into Car (CarId, Make, Model, Year, SeatingCapacity) values
(1, 'Toyota', '4Runner', 2023, 5),
(2, 'Honda', 'Civic', 2021, 5),
(3, 'BMW', 'I-8', 2024, 2);


/* Insert records into AvailabilityCalendar 
	Feb 2026 has 28 days, each car gets 1 record/day,
	IsAvailable = 1 for all */
declare @CarId int = 1;
declare @Date date;

while @CarId <= 3
begin
	set @Date = '2026-02-01';
	while @Date <= '2026-02-28'
	begin
		insert into AvailabilityCalendar (Date, CarId, IsAvailable)
		values (@Date, @CarId, 1);
		set @Date = DATEADD(day, 1, @Date);
	end
	set @CarId = @CarId + 1;
end

go


/* Stored Procedure - sp_ReserveCar */
create or alter procedure sp_ReserveCar
	@CarId int,
	@ReservationStartDate date,
	@ReservationEndDate date
as
begin
	set nocount on;

	-- Check if car is available for ALL dates in requested range
	declare @UnavailableCount int;

	select @UnavailableCount = COUNT(*)
	from AvailabilityCalendar
	where CarId = @CarId
	and Date between @ReservationStartDate and @ReservationEndDate
	and IsAvailable = 0;

	if @UnavailableCount > 0
	begin
		print 'Car not available for the requested dates.'
	end
	else
	begin
		-- Add reservation 
		insert into ReservationDetails (CarId, ReservationStartDate, ReservationEndDate)
		values (@CarId, @ReservationStartDate, @ReservationEndDate);

		-- Mark dates as unavailable in AvailabilityCalendar
		update AvailabilityCalendar
		set IsAvailable = 0
		where CarId = @CarId
			and Date between @ReservationStartDate and @ReservationEndDate;
		print 'Reservation Successful!';
	end
end;

go

/* Stored procedure test */ 
-- Test 1: Reserve Car 1 from Feb 5-7
exec sp_ReserveCar @CarId = 1, @ReservationStartDate = '2026-02-05', @ReservationEndDate = '2026-02-07';

-- Test 2: Reserve Car 1 from Feb 6-8, should fail
exec sp_ReserveCar @CarId = 1, @ReservationStartDate = '2026-02-06', @ReservationEndDate = '2026-02-08';

-- Test 3: Reserve Car 2 for full month
exec sp_ReserveCar @CarId = 2, @ReservationStartDate = '2026-02-01', @ReservationEndDate = '2026-02-28';

-- Test 4: Reserve Car 3 for single day, Feb 18
exec sp_ReserveCar @CarId = 3, @ReservationStartDate = '2026-02-18', @ReservationEndDate = '2026-02-18';

-- Test 5: Reseve Car 3 for Feb 15-21, should fail
exec sp_ReserveCar @CarId = 3, @ReservationStartDate = '2026-02-15', @ReservationEndDate = '2026-02-21';

-- Test 6: Reserve Car 3 for Feb 11-17
exec sp_ReserveCar @CarId = 3, @ReservationStartDate = '2026-02-11', @ReservationEndDate = '2026-02-17';

go


/* SQL Queries */ 

/* All reservations for CarId = 1
	Columns: CarId, Make, ReservationStartDate, ReservationEndDate */
select 
	c.CarId,
	c.Make,
	rd.ReservationStartDate,
	rd.ReservationEndDate
from ReservationDetails rd
join Car c on rd.CarId = c.CarId
where rd.CarId = 1;


/* All reservations for CarId = 2 for month of Feb 2026
	Columns: CarId, Year, SeatingCapacity, ReservationStartDate, ReservationEndDate*/
select
	c.CarId,
	c.Year,
	c.SeatingCapacity,
	rd.ReservationStartDate,
	rd.ReservationEndDate
from ReservationDetails rd
join Car c on rd.CarId = c.CarId
where rd.CarId = 2
	and rd.ReservationStartDate >= '2026-02-01'
	and rd.ReservationEndDate <= '2026-02-28';


/* How many times CarId = 1 and CarId = 2 were reserved in Feb 2026 */
select
	c.CarId,
	c.Make,
	count(rd.ReservationDetailId) as ReservationCount
From Car c
left join ReservationDetails rd
	on c.CarId = rd.CarId
	and rd.ReservationStartDate >= '2026-02-01'
	and rd.ReservationEndDate <= '2026-02-28'
where c.CarId IN (1, 2)
group by c.CarId, c.Make;


/* All reservations for CarId = 3 
	Columns: CarId, Make, ReservationStartDate, ReservationEndDate*/
select
	c.CarId,
	c.Make,
	rd.ReservationStartDate, 
	rd.ReservationEndDate
from ReservationDetails rd
join Car c on rd.CarId = c.CarId
where rd.CarId = 3;

/* All reservations for all cars
	Columns: CarId, Make, Model, Year, SeatingCapacity, ReservationStartDate, ReservationEndDate */
select 
	c.CarId,
	c.Make,
	c.Model,
	c.Year,
	c.SeatingCapacity,
	rd.ReservationStartDate,
	rd.ReservationEndDate
from ReservationDetails rd
join Car c on rd.CarId = c.CarId
order by c.CarId, rd.ReservationStartDate;
