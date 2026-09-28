# KijaniKiosk Production Server — Security Posture Summary

**Prepared for:** Nia
**Prepared by:** Amina
**Scope:** Foundational security decisions for the dedicated payments production server

## Overview

This document explains, in plain terms, the security decisions built
into the new production server before any payments traffic touches it.
The goal was simple: assume the server will eventually be attacked or
misused, and make sure that even if one part of it is compromised, the
damage stays contained rather than spreading.

Every decision below was tested, not just configured. Each one was
verified working on the actual server before being considered done, and
each one was checked against the question "does this actually make us
safer, or does it just look safer." Two ideas that looked good on paper
were rejected specifically because testing showed they would create
problems once real transaction processing is running, even though they
would have looked slightly better on a technical score. I chose the
option that is genuinely safer and reliable over the one that scores
best on paper.

## What I Did

| Control | What it does | Risk mitigated |
|---|---|---|
| Dedicated service accounts with no login ability | Each of the three services (the customer-facing API, the payments processor, and the logging system) runs under its own separate identity, and none of those identities can be used to log into the server directly | Stops a compromised service from being used as a stepping stone to log in and explore the rest of the server |
| Locked-down configuration files | Each service's configuration and secrets are stored in a file only that one service can read, not shared with the others | If one service is compromised, the attacker cannot read the payments service's credentials just because they share the same server |
| Strict filesystem isolation | The payments service can only write to one specific folder (its own log location); everything else on the server appears read-only or invisible to it, including areas that normally would let a program change system settings | Even a fully compromised payments process cannot modify the server itself, install anything persistent, or tamper with system-level settings |
| Removed unnecessary system permissions | The payments service has had almost every special system-level permission stripped away, keeping only what it strictly needs to run | Closes off dozens of ways a compromised process could otherwise escalate its own access or interfere with the rest of the machine |
| Network access restricted by source | Remote access to the server (for SSH, the web interface, and the payments health check) is only permitted from our own internal monitoring network, not from the public internet | Removes the payments port and administrative access from the reach of random internet scanning and opportunistic attacks |
| Internal-only payments port | The payments service's internal communication port is explicitly blocked from outside access, while still allowing the required internal connection between the website and the payments service | Prevents the payments processing port from being reachable from outside at all, closing a door that has no legitimate external use |
| Access model verified to survive routine maintenance | I specifically tested that daily log file cleanup does not accidentally lock any service out of the logs it needs, or grant access it should not have | Prevents a quiet, easy-to-miss security regression that would otherwise reappear every time logs rotate, potentially for months before anyone noticed |
| Structured, automatic health verification | The server automatically checks that each service is reachable, writes the result to a file that only the right people and systems can read, and this check now runs every time the server is provisioned or updated | Gives us an early warning system and a paper trail, rather than discovering an outage only when a customer reports it |

## Two Things I Chose Not to Do

During testing, I found two settings that would have produced a
slightly better technical security score, and rejected both because
they would have caused real problems once actual payment processing is
running on this server, not just in testing.

The first would have completely cut the payments service off from any
network communication at all. It tested well only because the software
that will eventually run this service is not installed yet, so nothing
was actually trying to send or receive data during my test. Once real
payment processing goes live, this setting would block it entirely,
including the connection to our own internal monitoring system.

The second would have made the service's underlying system identity
change randomly every time the server restarts, rather than staying
fixed. This also tested well in isolation, but our entire permissions
model depends on that identity staying the same and predictable, so it
introduced a shift of the whole security model to a spot from which it
would not survive a normal restart.

Both are documented in detail in the engineering notes in case either
becomes appropriate at a later stage, under different conditions.

## What This Does Not Protect Against

Being direct about limits: this work covers how the server itself is
configured and locked down. It does not yet cover the security of the
payments application code that will run on top of it, since that code
does not exist yet. It does not include monitoring alerts that
automatically notify a person when something goes wrong; right now the
health check writes a record, but nobody is automatically paged if that
record shows a problem. It does not cover protection against a
compromised employee account with legitimate access, encryption of data
while it is stored on disk, or a formal incident response plan for what
to do if a breach is detected. Those are next steps once the
foundation is proven stable, but they are genuinely not done yet, and I
would rather say so plainly than let this document imply more coverage
than currently exists.
