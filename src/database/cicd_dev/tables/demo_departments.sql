create table cicd_dev.demo_departments (
    department_id   number,
    department_name varchar2(100 byte) not null enable
);

alter table cicd_dev.demo_departments
    add primary key (department_id)
    using index enable;