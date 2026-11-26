create table cicd_dev.demo_countries (
    country_id   number,
    country_name varchar2(100 byte) not null enable,
    country_code varchar2(2 byte) not null enable
);

alter table cicd_dev.demo_countries
    add primary key (country_id)
    using index enable;