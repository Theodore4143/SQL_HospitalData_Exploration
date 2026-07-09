USE [SQL Case Studies]
select * from dim_patient
-- Data Cleaning(Patient table)
	-- Remove patient rows where first name is missing
	-- Standardize firstname and lastname to proper case and create a new fullname column
	-- Gender value should be Male or Female only
	-- Split citystatecountry to city,state and country
create table dim_patient_clean
				( patient_id varchar(20) primary key,
				FullName varchar(50),
				Gender varchar(10),
				DOB date,
				city varchar(50),
				State varchar(50),
				Country varchar(50)
				)
insert into dim_patient_clean(patient_id,FullName,Gender,DOB,city,State,Country)
select p.patientid,
Upper(left(ltrim(RTRIM(p.firstname)),1)) + lower(SUBSTRING(ltrim(RTRIM(p.firstname)),2,len(ltrim(RTRIM(p.firstname)))))
+ ' ' +
Upper(left(ltrim(RTRIM(p.lastname)),1)) + lower(SUBSTRING(ltrim(RTRIM(p.lastname)),2,len(ltrim(RTRIM(p.lastname))))) as
fullname,
Case
	when p.Gender='M' then 'Male'
	when p.Gender='F' then 'Female'
	else p.Gender
end as Gender,
p.DOB,
parsename(REPLACE(citystatecountry,',','.'),3) as City,
parsename(REPLACE(citystatecountry,',','.'),2) as State,
parsename(REPLACE(citystatecountry,',','.'),1) as Country
from dim_patient p
where p.firstname is not null 

select * from dim_patient_clean

-- Data Cleaning (Department table)
	-- Remove rows where department category is null
	-- Remove HOD and DepartmentName column(Repeatative)
	-- Use Specialization as departmentName column

create table dim_department_clean(
						DepartmentID varchar(20) primary key,
						DepartmentName varchar(50),
						DepartmentCategory varchar(50)
						)
insert into dim_department_clean(DepartmentID,DepartmentName,DepartmentCategory)
select DepartmentID,Specialization as DepartmentName,DepartmentCategory 
from Dim_Department 
where DepartmentCategory is not Null

select * from dim_department_clean

-- Data cleaning (patient visit table)
-- Merge yearly visit table (Year 2020-2025) into one consolidated patient visit table
create table patient_visits(
				VisitID varchar(20) primary key,
				PatientID varchar(20),
				DoctorID varchar(20),
				DepartmentID varchar(20),
				DiagnosisID varchar(20),
				TreatmentID varchar(20),
				PaymentMethodID varchar(20),
				VisitDate date,
				VisitTime time,
				DischargeDate date,
				BillAmount Decimal(18,2),
				InsuranceAmount Decimal(18,2),
				SatisfactionScore int,
				WaitTimeMinutes int
				
foreign key (PatientID)  references dim_patient_clean(Patient_id),
foreign key (DoctorID)   references dim_Doctor(DoctorID),
foreign key (DepartmentID) references dim_department_clean(DepartmentID),
foreign key (DiagnosisID) references dim_Diagnosis(DiagnosisID),
foreign key (TreatmentID) references dim_treatment(TreatmentID),
foreign key (PaymentMethodID) references dim_PaymentMethod(PaymentMethodID)
)

insert into patient_visits(VisitID,PatientID ,
				DoctorID ,
				DepartmentID ,
				DiagnosisID ,
				TreatmentID ,
				PaymentMethodID ,
				VisitDate ,
				VisitTime ,
				DischargeDate ,
				BillAmount ,
				InsuranceAmount ,
				SatisfactionScore ,
				WaitTimeMinutes
				)
select VisitID,PatientID ,DoctorID ,DepartmentID ,DiagnosisID ,TreatmentID ,
PaymentMethodID,VisitDate,VisitTime,DischargeDate,BillAmount ,
InsuranceAmount ,SatisfactionScore,WaitTimeMinutes
from PatientVisits_2020_2021
union all
select VisitID,PatientID ,DoctorID ,DepartmentID ,DiagnosisID ,TreatmentID ,
PaymentMethodID,VisitDate,VisitTime,DischargeDate,BillAmount ,
InsuranceAmount ,SatisfactionScore,WaitTimeMinutes
from PatientVisits_2022_2023
union all
select VisitID,PatientID ,DoctorID ,DepartmentID ,DiagnosisID ,TreatmentID ,
PaymentMethodID,VisitDate,VisitTime,DischargeDate,BillAmount ,
InsuranceAmount ,SatisfactionScore,WaitTimeMinutes
from PatientVisits_2024
union all 
select VisitID,PatientID ,DoctorID ,DepartmentID ,DiagnosisID ,TreatmentID ,
PaymentMethodID,VisitDate,VisitTime,DischargeDate,BillAmount ,
InsuranceAmount ,SatisfactionScore,WaitTimeMinutes
from PatientVisits_2025



