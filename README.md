#Shields Up
This gem provides an alternative implementation of strong_parameters. 
##usage (we basically use the same grammar as strong parameter)
- **Read this first**: [Strong Parameter Usage](http://edgeguides.rubyonrails.org/action_controller_overview.html#strong-parameters)


##Difference to strong parameter
- enable ShieldsUp<br>

in Gemfile<br>
```
  gem 'shields_up'   
```
in controllers<br>
```
  include ShieldsUp   
```

- ShieldsUp::Parameter type only allow bracket operation[], permit and require.
- You can only use symbol to access variables.<br>

Example:<br>
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

- How to disable shields up.<br>
For legacy code which is so hard to have a full list of variables should be permitted, you can disable shields_up but you should be careful for doing that.
<pre>
params.with_shields_down do
  your_code
end
<br>
<b>Note: this block can not be nested. This means inside with_shields_down there should be no with_shields_down<br>
So, you should be careful if you are using it inside a gem.
</b>
</pre>

#things should be noticed:
- to update and destroy associated records, permit **:id, :_destroy **when you use accepts_nested_attributes_for in combination with a has_many association. <br> 

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
- **use hash inside permit statment** for non scaler type.<br>

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
    
#limitations
we do not support array of arrays 
``` 
{'company' => [['a','b'],['a','b']]}
``` 
Similar to strong parameter, this gem was designed with the most common use cases in mind. It is not meant as a silver bullet to handle all your whitelisting problems. However you can easily disable the API, and whitelist the parameter with your own code to adapt to your situation.<br>

