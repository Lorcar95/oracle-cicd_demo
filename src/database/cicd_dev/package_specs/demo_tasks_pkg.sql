create or replace package cicd_dev.demo_tasks_pkg as
    procedure add_task (
        p_task_name in varchar2
    );

    procedure complete_task (
        p_task_id in number
    );

end demo_tasks_pkg;
/


-- sqlcl_snapshot {"hash":"13855d35c5b07c0df436564f8f68a294f2edd328","type":"PACKAGE_SPEC","name":"DEMO_TASKS_PKG","schemaName":"CICD_DEV","sxml":""}