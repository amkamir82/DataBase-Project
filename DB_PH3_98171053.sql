#1
create table Card (
card_number integer primary key,
credit double precision default 0,
price_per_km double precision not null,
price_per_enterance double precision not null
);
alter table card add constraint credit check (credit > 0);



#2
create table Citizen (
citizen_code integer primary key
);


#3
create table CitizenHasCard (
card_number integer,
citizen_code integer references Citizen(citizen_code) on delete cascade on update cascade,
primary key(card_number, citizen_code)
);


#4
create table CitizenSubmitsComplaint (
citizen_code integer references Citizen(citizen_code) on delete cascade on update cascade,
complaint_code integer,
primary key(citizen_code, complaint_code)
);


#5
create table Complaint (
complaint_id integer primary key,
submit_time timestamp not null,
duration time not null,
station_name varchar(50) not null,
metroline_number integer not null,
direction varchar(50) not null,
metrotraint_num integer not null
);



#6
create table Driver (
driver_code integer primary key,
name varchar(50) not null,
daily_complaint integer default 0,
min_work_hrs time not null,
time_of_working time not null
);
alter table driver add column sallary double precision default 0;



#7
create table DriverCitizen (
driver_code integer,
citizen_code integer references Citizen(citizen_code) on delete cascade on update cascade,
primary key(driver_code, citizen_code)
);


#8
create table DriverHaveFingerPrint (
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
fingerprint_id integer,
primary key(driver_code, fingerprint_id)
);


#9
create table Form (
form_id integer primary key,
type varchar(50) not null
);


#10
create table DriverHaveForm_Relation (
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
form_id integer references Form(form_id) on delete cascade on update cascade,
primary key(driver_code, form_id)
);


#11
create table DriverSchedule (
day varchar(50),
time_in time,
time_out time,
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
primary key(day, time_in, time_out, driver_code),
check (time_out > time_in)
);


#12
create table FingerPrint (
fingerprint_id integer primary key,
time_in time not null,
time_out time not null,
driver_code integer references Driver(driver_code) on delete cascade on update cascade
);
alter table fingerprint add column day varchar(50) not null;


#13
create table LineDeposit (
deposit_code integer primary key,
price_per_enterance double precision not null
);
alter table LineDeposit add constraint price_per_enterance check (price_per_enterance > 0);
alter table linedeposit add column deposit double precision default 0;

#14
create table Trip (
citizen_code integer references Citizen(citizen_code) on delete cascade on update cascade,
trip_id integer,
start_station varchar(50),
end_station varchar(50),
has_switched_station boolean not null,
primary key(citizen_code, trip_id)
);
alter table Trip add column card_number integer not null;
alter table trip add column metroline_num integer not null;


#15
create table MetroLine (
metroline_number integer primary key,
color varchar(50)
);


#16
create table LineSchedule (
train_num integer,
time_in time,
time_out time,
direction varchar(50),
metroline_number integer references MetroLine(metroline_number) on delete cascade on update cascade,
station_name varchar(50),
primary key(train_num, time_in, time_out, direction, metroline_number, station_name) ,
check (time_out > time_in)
);



#17
create table Manuciplity (
manuciplity_number integer primary key
);


#18
create table ManuciplityChooseDriver_Relation (
metroline_number integer,
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
manuciplity_number integer references Manuciplity(manuciplity_number) on delete cascade on update cascade,
primary key (metroline_number, driver_code, manuciplity_number)
);


#19
create table MetroLineHaveDeposit (
deposit_code integer references LineDeposit(deposit_code) on delete cascade on update cascade,
metroline_number integer references MetroLine(metroline_number) on delete cascade on update cascade,
primary key(deposit_code, metroline_number)
);


#20
create table MetroLineHaveDriver_Relation (
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
metroline_number integer references MetroLine(metroline_number) on delete cascade on update cascade,
primary key(driver_code, metroline_number)
);


#21
create table MetroTrain (
metrotrain_number integer primary key
);


#22
create table Station (
station_name varchar(50) primary key,
address varchar(50) not null,
displacement integer not null
);
alter table Station add constraint displacement CHECK (displacement > 0);
alter table metroline add column start_station varchar(50) not null;
alter table metroline add column end_station varchar(50) not null;


#23
create table MetroLineHaveStation_Ralation (
metroline_number integer references MetroLine(metroline_number) on delete cascade on update cascade,
station_name varchar(50) references Station(station_name) on delete cascade on update cascade,
primary key(metroline_number, station_name)
);



#24
create table Supervisor (
supervisor_code integer primary key,
supervisir_name varchar(50) not null
);


#25
create table MetroLineHaveSupervisor (
metroline_num integer,
supervisor_code integer references Supervisor(supervisor_code) on delete cascade on update cascade,
primary key(metroline_num, supervisor_code)
);


#26
create table MetroTrainHaveDriver_Relation (
driver_code integer references Driver(driver_code) on delete cascade on update cascade,
metrotrain_number integer references MetroTrain(metrotrain_number) on delete cascade on update cascade,
primary key(driver_code, metrotrain_number)
);

#27
create table SupervisorCitizen (
supervisor_code integer,
citizen_code integer references Citizen(citizen_code) on update cascade on delete cascade,
primary key(citizen_code, supervisor_code)
);


#28
create table LineDepositTripPay_Relation (
trip_id integer,
citizen_code integer,
deposit_code integer references LineDeposit(deposit_code) on update cascade on delete cascade,
FOREIGN KEY (trip_id, citizen_code) REFERENCES Trip (trip_id, citizen_code),
primary key(trip_id, citizen_code, deposit_code)
);











#triggers
#1
CREATE FUNCTION decrease_credit_for_pull_card() RETURNS trigger AS $emp_stamp$
	DECLARE tmpCredit integer;
    BEGIN
		
		select credit into tmpCredit from card where card_number = NEW.card_number;
	
		IF (tmpCredit-500 < 0) THEN
       		RAISE EXCEPTION '% credit kame', tmpCredit;
		ELSIF NEW.has_switched_station=FALSE THEN
			UPDATE Card
			SET credit = tmpCredit-500
			WHERE card_number = NEW.card_number;
		END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;
CREATE TRIGGER decrease_card_credit
    BEFORE INSERT ON Trip
    FOR EACH ROW
    EXECUTE PROCEDURE decrease_credit_for_pull_card();



#2
CREATE FUNCTION decrease_credit_for_done_trip() RETURNS trigger AS $emp_stamp$
	DECLARE tmpCredit integer;
	DECLARE tmpprice_per_km integer;
	DECLARE tmpStartDisplacement integer;
	DECLARE tmpEndDisplacement integer;
	DECLARE tmpStation varchar(50);
    BEGIN
	
		select station_name into tmpStation from station where station_name = NEW.end_station;
		IF NEW.end_station=tmpStation THEN
       		select displacement into tmpStartDisplacement from station where station_name = OLD.start_station;
		select displacement into tmpEndDisplacement from station where station_name = NEW.end_station;
		select credit into tmpCredit from card where card_number = OLD.card_number;
		select price_per_km into tmpprice_per_km from card where card_number = OLD.card_number;
		
			UPDATE Card
			SET credit = tmpCredit+500-(tmpprice_per_km*ABS(tmpStartDisplacement-tmpEndDisplacement))
			WHERE card_number = OLD.card_number;
		ELSE
			RAISE EXCEPTION '% vojod nadare', tmpCredit;
		END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER decrease_card_credit_after_done_trip
    AFTER UPDATE ON Trip
    FOR EACH ROW
	WHEN (OLD.end_station IS DISTINCT FROM NEW.end_station)
    EXECUTE PROCEDURE decrease_credit_for_done_trip();



#3 will be check
CREATE FUNCTION increase_credit_to_linedeposit() RETURNS trigger AS $emp_stamp$
	DECLARE tmpLineDeposit integer;
	DECLARE tmpDeposit double precision;
	DECLARE tmpPriceEnterance double precision;
    BEGIN
		
		select deposit_code into tmpLineDeposit 
		from MetrolineHaveDeposit where metroline_number=NEW.metroline_num;
		
		select deposit into tmpDeposit 
		from linedeposit where deposit_code=tmpLineDeposit;
		
		select price_per_enterance into tmpPriceEnterance 
		from linedeposit where deposit_code=tmpLineDeposit;
		
		UPDATE LineDeposit
		SET deposit = deposit+tmpPriceEnterance
		WHERE deposit_code = tmpLineDeposit;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER increase_credit
    BEFORE INSERT ON Trip
    FOR EACH ROW
    EXECUTE PROCEDURE increase_credit_to_linedeposit();




#4
CREATE FUNCTION increase_credit_for_change_line() RETURNS trigger AS $emp_stamp$
	DECLARE tmpLineDeposit integer;
	DECLARE tmpDeposit double precision;
	DECLARE tmpPriceEnterance double precision;
    BEGIN
	
		IF NEW.has_switched_station=TRUE THEN
			select deposit_code into tmpLineDeposit 
			from MetrolineHaveDeposit where metroline_number=NEW.metroline_num;
		
			select deposit into tmpDeposit 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			select price_per_enterance into tmpPriceEnterance 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			UPDATE LineDeposit
			SET deposit = deposit+tmpPriceEnterance
			WHERE deposit_code = tmpLineDeposit;
			END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;
CREATE TRIGGER increase_credit_for_change_line_trigger
    BEFORE UPDATE ON Trip
    FOR EACH ROW
    EXECUTE PROCEDURE increase_credit_for_change_line();





#5
CREATE FUNCTION driver_complaint_func() RETURNS trigger AS $emp_stamp$
	DECLARE c record;
    BEGIN
	
		update driver set time_of_working='0:0:0' where driver_code=OLD.driver_code;
		
        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER driver_complaint_trigger
    after update ON driver
    FOR EACH ROW
	WHEN (OLD.daily_complaint IS DISTINCT FROM NEW.daily_complaint)
    EXECUTE PROCEDURE driver_complaint_func();





#6
CREATE FUNCTION complaint_func() RETURNS trigger AS $emp_stamp$
	DECLARE c record;
    BEGIN
	
		for c in select driver_code, count(complaint_id) as cnt from metrotrainhavedriver_relation join complaint
			on metrotrainhavedriver_relation.metrotrain_number=complaint.metrotraint_num
			group by(driver_code)
			having (count(complaint_id)>1)
		loop
			update driver set daily_complaint=c.cnt where driver_code=c.driver_code;
		end loop;
		
        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;

CREATE TRIGGER complaint_trigger
    after insert ON complaint
    FOR EACH ROW
    EXECUTE PROCEDURE complaint_func();




#7







##########VIEW#######
create view V1 select driver_code, sum(time_out-time_in) as sum from fingerprint group by (driver_code)


create view V2 select linedeposit.deposit_code, metroline_number, deposit
from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code


create view V3 select MetroLineHaveDriver_Relation.driver_code, MetroLineHaveDriver_Relation.metroline_number, linedeposit.deposit
from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code
join MetroLineHaveDriver_Relation on MetroLineHaveDriver_Relation.metroline_number = metrolinehavedeposit.metroline_number



create view V4 select MetroLineHaveDriver_Relation.driver_code, T1.sum, MetroLineHaveDriver_Relation.metroline_number, linedeposit.deposit
from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code
join MetroLineHaveDriver_Relation on MetroLineHaveDriver_Relation.metroline_number = metrolinehavedeposit.metroline_number
join (select driver_code, sum(time_out-time_in) as sum
	 from fingerprint group by (driver_code, day) having (day='sat')) T1 on T1.driver_code=MetroLineHaveDriver_Relation.driver_code



create view V5 select driver_code, count(complaint_id) as cnt from metrotrainhavedriver_relation join complaint
on metrotrainhavedriver_relation.metrotrain_number=complaint.metrotraint_num
group by(driver_code)
having (count(complaint_id)>1)


















create table timeschedule(
code integer primary key,
day varchar(50) not null
);

alter table fingerprint add primary key driver_code; 
select * from timeschedule
insert into complaint values (2, current_timestamp, current_timestamp, 'a', 1, 'ok', 1)
select metrotraint_num, count(complaint_id) as from complaint group by(metrotraint_num)

select linedeposit.deposit_code, metroline_number, deposit
from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code
select * from linedeposit
select * from driver
select * from MetroLineHaveDriver_Relation
select * from fingerprint
select * from driverhavefingerprint
update fingerprint set driver_code = 2 where fingerprint_id = 3
select * from complaint
 
insert into MetroLineHaveDriver_Relation values (2,1)

select driver_code, sum(time_out-time_in) as sum from fingerprint group by (driver_code)

select * from 

select driver_code, sum(time_out-time_in) as sum
from fingerprint group by (driver_code, day) having (day='sat');

delete from driverhavefingerprint where fingerprint_id=2
delete from fingerprint where fingerprint_id=2
insert into driver values (1, 'a', 0, '24:0:0', '0:0:0');
insert into driverschedule values ('sat', '10:0:0', '20:0:0', 2);
insert into fingerprint values (2, '13:0:0', '15:0:0', 'sat');
insert into driverhavefingerprint values (2, 3);


select MetroLineHaveDriver_Relation.driver_code, T1.sum, MetroLineHaveDriver_Relation.metroline_number, linedeposit.deposit
from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code
join MetroLineHaveDriver_Relation on MetroLineHaveDriver_Relation.metroline_number = metrolinehavedeposit.metroline_number
join (select driver_code, sum(time_out-time_in) as sum
	 from fingerprint group by (driver_code, day) having (day='sat')) T1 on T1.driver_code=MetroLineHaveDriver_Relation.driver_code



DROP TRIGGER devide_sallary_trigger ON Trip;
DROP FUNCTION devide_sallary_func;





CREATE FUNCTION devide_sallary_func() RETURNS trigger AS $emp_stamp$
	DECLARE tmpDriverId integer;
    BEGIN
	
	
		for c in select metrotraint_num, count(complaint_id) as cnt
		from complaint group by(metrotraint_num)
		loop
			IF cnt >3 then
				update driver set felan =0 where felan = felan
		
		for f in select driver_code, sum(time_out-time_in) as sum
		from fingerprint group by (driver_code, day) having (day=tmpDay)
    	loop 
			update Driver set sallary 
   		end loop
	
	
		IF NEW.has_switched_station=TRUE THEN
			select deposit_code into tmpLineDeposit 
			from MetrolineHaveDeposit where metroline_number=NEW.metroline_num;
		
			select deposit into tmpDeposit 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			select price_per_enterance into tmpPriceEnterance 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			UPDATE LineDeposit
			SET deposit = deposit+tmpPriceEnterance
			WHERE deposit_code = tmpLineDeposit;
			END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;
CREATE TRIGGER complaint_trigger
    after insert ON complaint
    FOR EACH ROW
    EXECUTE PROCEDURE devide_sallary_func();
















CREATE FUNCTION devide_sallary_func() RETURNS trigger AS $emp_stamp$
	DECLARE tmpDay integer;
	DECLARE tmpDeposit double precision;
	DECLARE tmpPriceEnterance double precision;
	DECLARE f table;
    BEGIN
	
		select day into tmpDay where code=NEW.day_code;
		
		select driver_code, sum(time_out-time_in) as sum
		from fingerprint group by (driver_code, day) having (day=tmpDay);
		
		select linedeposit.deposit_code, metroline_number, deposit
		from metrolinehavedeposit join linedeposit on metrolinehavedeposit.deposit_code = linedeposit.deposit_code

		
		for f in select driver_code, sum(time_out-time_in) as sum
		from fingerprint group by (driver_code, day) having (day=tmpDay)
    	loop 
			update Driver set sallary 
   		end loop
	
	
		IF NEW.has_switched_station=TRUE THEN
			select deposit_code into tmpLineDeposit 
			from MetrolineHaveDeposit where metroline_number=NEW.metroline_num;
		
			select deposit into tmpDeposit 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			select price_per_enterance into tmpPriceEnterance 
			from linedeposit where deposit_code=tmpLineDeposit;
		
			UPDATE LineDeposit
			SET deposit = deposit+tmpPriceEnterance
			WHERE deposit_code = tmpLineDeposit;
			END IF;

        RETURN NEW;
    END;
$emp_stamp$ LANGUAGE plpgsql;
CREATE TRIGGER devide_sallary_trigger
    after insert ON timeschedule
    FOR EACH ROW
    EXECUTE PROCEDURE devide_sallary_func();