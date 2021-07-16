gds readonly true  ; # preserve all GDS data as-is
gds rescale false
gds read user_project_wrapper.gds  ; # original version from openlane
load temp
cellname delete user_project_wrapper  ; # remove the original top level cell
gds readonly false
gds rescale true
gds noduplicates true  ; # ignore all cells that have already been loaded
gds read hand-routed_old.gds  ; # final hand-edited version
load user_project_wrapper
gds write hand-routed.gds   ; # using Po-Han's name for the final output

exit
