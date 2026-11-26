create table cicd_dev.demo_products (
    product_id   number,
    product_name varchar2(100 byte) not null enable,
    price        number(10,2)
);

alter table cicd_dev.demo_products add primary key ( product_id )
    using index enable;