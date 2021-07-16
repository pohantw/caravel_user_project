# everything reading from vendor cannot be touched
gds readonly true

gds read user_project_wrapper.gds
load user_project_wrapper

see no *
see met4
see met5
see via4
see via3

select top cell
property GDS_FILE ""
