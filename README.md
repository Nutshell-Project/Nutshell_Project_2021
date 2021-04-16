# Nutshell Project
# Description: 
Using Flex and Bison, we created a pseudo shell resembling the linux-based shell archetype in C++. This project was done with the combined efforts of **Andrew Dang** and **Jayden Jones**. Listed below are the features we implemented/failed to implement as well as their respective contributors.
# Incomplete Features: 
```
Redirecting I/O with Non-built-in Commands
```
The code on our separate branches successfully implemented I/O manipulation. However, we were unable to merge the code base successfully before the deadline. *(Andrew Dang)*
```
Using Pipes with Non-built-in Commands
```
Pipe detection worked on our branches, but combining caused unforseen errors. Thus, the functionality was left bare-bones on final submission. *(Andrew Dang)*
```
Running Non-built-in Commands in Background
```
`&` token successfully identified. Branch merge was incomplete. Code left unimplemented in submission. *(Andrew Dang)*
```
Using both Pipes and I/O Redirection, combined, with Non-built-in Commands
```
Unfortunately, time was of the essence and both of us decided to scrap the idea and focus on other functionalities that were more feasible. *(Both)*
```
Wildcard Matching
```
Same as above. *(Both)*
```
File name completion
```
Same as above *(Both)*
```
Tilde Expansion
```
Functionality complete in branch `non-built-command`. No implementation in `master` to avoid errors.*(Andrew Dang)*
# Complete Features:
```
Built-In Commands (setenv variable word, printenv, unsetenv variable, cd, alias name word, unalias name, alias, bye, infinite loop alias-expansion detection)
```
All built-in commands except for `cd` were implemented by *Jayden Jones*
`cd` done by *Andrew Dang*. Rest of functionality left on other branch.

```
Non-built-in Commands (ls, echo, more, etc...)
```
Combined effort and debugging resulted in completed functionality. Though majority of time and effort was *Andrew Dang*.
```
Environment Variable Expansion
```
In line with working on built-in commands. *(Jayden Jones)*
```
Alias Expansion
```
*(Jayden Jones)*
```
Shell Robustness
```
*(Andrew Dang and Jayden Jones)*
```
Error Handling and Reporting
```
*(Andrew Dang and Jayden Jones)*

#
# Author
Andrew Dang, Jayden Jones
