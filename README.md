[![Build Status](https://travis-ci.org/appfolio/shields_up.png)](https://travis-ci.org/appfolio/shields_up)
[![Code Climate](https://codeclimate.com/github/appfolio/shields_up/badges/gpa.svg)](https://codeclimate.com/github/appfolio/shields_up)
[![Test Coverage](https://codeclimate.com/github/appfolio/shields_up/badges/coverage.svg)](https://codeclimate.com/github/appfolio/shields_up)

#Shields Up
This gem provides an alternative implementation of strong_parameters.
##usage (the grammar for permit statements is the same as strong_parameters)
- **Read this first**: [Strong Parameter Usage](http://edgeguides.rubyonrails.org/action_controller_overview.html#strong-parameters)


##Differences to strong parameter
params.symbolize_keys (or similar functions) will disable strong_parameters
protection silently. With ShieldsUp this can not happen.

## Enable ShieldsUp<br>

in Gemfile<br>
```
  gem 'shields_up'
```
in controllers<br>
```
  include ShieldsUp
```

- ShieldsUp::Parameter type only allows three operations: [], permit and require.
- You can use symbols or strings to access variables.<br>

##Example:<br>
```
params[:company]
```
not:
```
params["company"]
```
or
```
params.fetch(:company)
params.fetch("company")
```

##A more complicated example:<br>
```
params.permit(:company => [:address, :enabled])
```
not:
```
params.permit("company" => [:address, "enabled"])
```

## How to disable shields up.<br>
If you have a bunch of legacy code in a controller or you call into gems whose
parameter handling
you do not control (e.g. devise) you can disable shields_up at your own risk.
Similar to holding a lock around critical sections these blocks should generally be kept as short as possible.
<pre>
params.with_shields_down do
  call_some_legacy_stuff_or_gem()
end
</pre>
<br>
- with_shields_down can not be nested. This means inside with_shields_down there should be no with_shields_down
- the places in an application disabling parameter protection are such explicit and can be accounted for during an audit
</b>

##Common Pitfalls:
- *to update and destroy associated records, permit <i>:id,</i> and <i> :_destroy </i> when you use accepts_nested_attributes_for in combination with a has_many association. <br>

Example:
```
# To whitelist the following data:
# {"applicant" => {"email_address" => "some@email.com",
#                  "contact_info_attributes" => { "1" => {"salutation" => "First Salutation"},
#                                        "2" => {"salutation" => "Second Salutation"}}}}
    params.permit(
        {:applicant => [
            :email_address,
            {:contact_info_attributes => [:salutation, :id, :_destroy]},
        ]}
    )
```
- *use hash inside permit statment** for non scaler type.<br>

Example:
```
# To whitelist the following data:
# {"applicant" => {"email_address" => "some@email.com",
#                  "info" => { "first_name" => 'First', "last_name" => 'Last'}}}
```
<pre>
    params.permit(
        {:applicant => [
            :email_address,
            <b>{</b>:info => [:first_name, :last_name]<b>}</b>
        ]}
    )
</pre>

##Limitations
Similar to strong_parameters, this gem was designed with the most common use cases in mind. It is not meant as a silver bullet to handle all your whitelisting problems. However you can easily disable shields_up, and sanitize the parameter with your own code to adapt to your situation.<br>

In order to keep our grammar compatible to strong_parameters it is not possible
to express permission for array of arrays:
```
{'company' => [['a','b'],['a','b']]}
```
