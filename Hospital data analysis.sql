use [SQL Case Studies]
--Q1 For each doctor, Count how many distinct patient they have treated?
select d.DoctorID, 
d.FirstName + ' ' + d.LastName as DoctorName,
count(distinct v.patientID) as patient_treated
from patient_visits v
inner join Dim_Doctor d
on v.DoctorID = d.DoctorID
group by d.DoctorID,d.FirstName,d.LastName
order by patient_treated desc

--Q2 Show the revenue split by each payment method, Along with total visits.
select p.PaymentMethod,sum(v.BillAmount) as revenue,count(*) as total_visits 
from patient_visits v
join Dim_PaymentMethod p
on v.PaymentMethodID = p.PaymentMethodID
group by p.PaymentMethod
order by revenue,total_visits desc

/*Q3 Categorize patient into age groups and calculate the average bill amount for each age band.
(Assume age at time of visit based on visitdate.)*/
with cte_patientAge as
	(select v.VisitID,v.BillAmount,
	case
		when DATEDIFF(year,p.dob,v.visitdate)<18 then '0-17'
		when DATEDIFF(year,p.dob,v.visitdate) between 18 and 35 then '18-35'
		when DATEDIFF(year,p.dob,v.visitdate) between 36 and 55 then '36-55'
		else '55+'
		end as AgeBucket
	from patient_visits v
	inner join dim_patient_clean p
	on v.PatientID = p.patient_id
	)
select AgeBucket,count(*) as TotalVisits,
cast(AVG(BillAmount) as decimal(10,2)) as avgBillAmount
from cte_patientAge
group by AgeBucket
order by
		case 
		   when AgeBucket='0-17' then 1
		   when AgeBucket='18-35' then 2
		   when AgeBucket='36-55' then 3
		   when AgeBucket='55+' then 4
		end 

--Q4 Find total revenue and number of visits for each department.
select d.DepartmentID,d.DepartmentName,sum(v.BillAmount) as TotaRevenue,count(*) as totalVisits 
from patient_visits v
join dim_department_clean d
on v.DepartmentID = d.DepartmentID
group by d.DepartmentID,d.DepartmentName
order by TotaRevenue desc

--Q5 Rank departments based on their total revenue within each department category.
select DepartmentCategory,DepartmentName,TotalRevenue,
RANK() over(partition by DepartmentCategory order by TotalRevenue desc) as rnk
from
	(select d.DepartmentName,d.DepartmentCategory,sum(v.BillAmount) as TotalRevenue
	from patient_visits v
	join dim_department_clean d
	on v.DepartmentID = d.DepartmentID
	group by d.DepartmentName,d.DepartmentCategory
	) t

--Q6 For each department, Find the average satisfaction score and average wait time.
select d.DepartmentName,
cast(avg(v.SatisfactionScore) as decimal(10,2)) as avgScore,
cast(avg(v.WaitTimeMinutes) as decimal(10,2)) as avgWaitTime
from patient_visits v
join dim_department_clean d
on v.departmentid = d.departmentid
group by d.DepartmentName
order by avgScore desc

--Q7 Compare the total number of hospital visits on weekdays vs weekend.
select daytype,count(*) as TotalVisits
from
	(select
	case 
		when DATENAME(weekday,VisitDate) in ('Saturday','Sunday') then 'Weekend'
		else 'Weekdays'
		end as DayType
	from patient_visits) t
group by DayType
order by TotalVisits desc

--Q8 For each month, Calculate total visits and a running cumulative total of visits.
with cte_visitdate as
	(select 
	DATEFROMPARTS(year(visitdate),MONTH(visitdate),1) as visitDates,
	count(*) as TotalVisits
	from patient_visits
	group by DATEFROMPARTS(year(visitdate),MONTH(visitdate),1)
	)
select visitDates,TotalVisits,
sum(totalvisits) 
over(order by visitdates rows between unbounded preceding and current row) as cumulativeVisits
from cte_visitdate

--Q9 Find the doctors with the highest average satisfaction score(Minimum 100 visits)

select DoctorID,fullname,totalVisits,avgSatisfactionScore
from
	(select d.DoctorID,d.FirstName + ' '+d.LastName as fullname,
	cast(AVG(v.SatisfactionScore) as decimal(10,2)) as avgSatisfactionScore,
	count(*) as totalVisits
	from patient_visits v
	join Dim_Doctor d
	on v.DoctorID = d.DoctorID
	group by  d.DoctorID, d.FirstName + ' '+d.LastName
	) t
where totalVisits>=100
order by avgSatisfactionScore desc

--Q10 Identify the most commonly prescribed treatment for each diagnosis.
with cte_diagnosis as
	(select d.DiagnosisID,d.DiagnosisName,t.treatmentname,count(*) as treatmentCount,
	rank() over(partition by d.DiagnosisName order by count(*) desc) as rnk
	from patient_visits v
	inner join Dim_Treatment t
	on v.TreatmentID = t.TreatmentID
	inner join Dim_Diagnosis d
	on v.DiagnosisID = d.DiagnosisID
	group by d.DiagnosisID,d.DiagnosisName,t.treatmentname
	)
select DiagnosisName,treatmentname,treatmentCount,rnk  
from cte_diagnosis
where rnk=1