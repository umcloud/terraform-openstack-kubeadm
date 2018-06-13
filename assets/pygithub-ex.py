#!/usr/bin/python3
from github import Github

token = "<EDITED>"
org = "umcloud-external"
team = "students-cd-18"

g = Github(login_or_token=token)
x = g.get_organization(org)
print ("\n".join([x.login for x in [t.get_members().get_page(0) for t in x.get_teams() if t.name == team][0]]))
