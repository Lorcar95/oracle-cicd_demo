create or replace package body cicd_dev.demo_tasks_pkg as

    procedure add_task (
        p_task_name in varchar2
    ) as
    begin
        insert into demo_tasks ( task_name ) values
            ( p_task_name );

    end add_task;

    procedure complete_task (
        p_task_id in number
    ) as
    begin
        update demo_tasks
        set
            status = 'DONE'
        where
            task_id = p_task_id;

    end complete_task;

end demo_tasks_pkg;
/


-- sqlcl_snapshot {"hash":"e466b9a2c53f78de456ab67f0fab00cdb85c4df2","type":"PACKAGE_BODY","name":"DEMO_TASKS_PKG","schemaName":"CICD_DEV","sxml":""}