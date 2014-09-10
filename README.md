This gem provides an alternative implementation of strong_parameters.
There are two ways to access parameters:
- to access a simple scalar using Hash-access syntax: params[:value]
- to access a complex structure using strong_parameters' syntax: params.permit[:value => [:subvalue, another_value:]]

In both cases, symbols should be used as keys.
