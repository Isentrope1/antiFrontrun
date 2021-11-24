
The anti-frontrunning mechansim works as follows:

Let's call the real registrant R and the frontrunner F.

R chooses some salt bytes32 and calls NameRegistry.preRegister(hash(name + salt)) which saves a mapping of hash(msg.sender + hash(name + salt)) -> timestamp.

Note:
1. name cannot be gleaned from this since F doesnt know salt
2. the preRegistration record only applies to R, not F

Then R calls register(name, salt). The name is given to user with the earliest preRegistration record. F cannot be the earliest preRegistration record without knowing name. 

The worst-case ordering of events is:

1. R preRegister mined
2. R register submitted. now F knows name
3. F preRegister mined
4. F register mined
5. R register mined

To avoid F temporarily owning name before step 5, I introduce a delay in awarding the name after registration.
