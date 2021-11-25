
The anti-frontrunning mechansim works as follows:

Let's call the real registrant R and the frontrunner F.

R chooses some salt bytes32 and calls NameRegistry.preRegister(hash(name + address + salt)) which saves record of hash(name + address + salt) -> timestamp.

Note:
1. F cannot glean name from preRegister as F doesnt know salt
2. the preRegistration record only applies to R, not F

Then R calls register(name, salt). The name is awarded to user with the earliest preRegistration record.

The worst-case ordering of events is:

1. R preRegister mined. F can't preregister because he doesnt know name
2. R register submitted. now F knows name
3. F preRegister mined
4. F register mined
5. R register mined

To avoid F temporarily owning name between steps 4 and 5, I introduce a delay in awarding the name after registration.
