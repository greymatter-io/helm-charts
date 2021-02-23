from keycloak import KeycloakAdmin
import os

keycloak_admin = KeycloakAdmin(server_url="http://a85482a33bd744aef8f46295cbc1d589-753440034.us-east-1.elb.amazonaws.com:80/auth/",
                               realm_name="greymatter",
                               user_realm_name="master",
                               client_secret_key=os.environ.get('KEYCLOAK_SECRET_KEY'),
                               verify=True)
        
# # Add user                       
# new_user = keycloak_admin.create_user({"email": "example@example.com",
#                     "username": "example@example.com",
#                     "enabled": True,
#                     "firstName": "Example",
#                     "lastName": "Example"})    
                                        
# # Add user and set password                    
# new_user = keycloak_admin.create_user({"email": "example@example.com",
#                     "username": "example@example.com",
#                     "enabled": True,
#                     "firstName": "Example",
#                     "lastName": "Example",
#                     "credentials": [{"value": "secret","type": "password",}]})                        

# # User counter
# count_users = keycloak_admin.users_count()

# # Get users Returns a list of users, filtered according to query parameters
# users = keycloak_admin.get_users({})

# # Get user ID from name
# user_id_keycloak = keycloak_admin.get_user_id("example@example.com")

# # Get User
# user = keycloak_admin.get_user("user-id-keycloak")

# # Update User
# response = keycloak_admin.update_user(user_id="user-id-keycloak", 
#                                       payload={'firstName': 'Example Update'})

# # Update User Password
# response = keycloak_admin.set_user_password(user_id="user-id-keycloak", password="secret", temporary=True)
#                                       