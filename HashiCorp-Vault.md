# HashiCorp Vault 

## Create new AppRole

1. Create App Role
```
vault write auth/approle/role/<my-approle-name> \
  token_policies="<my-approle-policy>"
```

2. Get role ID
```
vault read auth/approle/role/<my-approle-name>/role-id
```

3. Get Secret
```
vault write -f auth/approle/role/<my-approle-name>/secret-id
```

4. To be able to use **vault** provider in `.tf` file, access policy needs following lines:

```
path "auth/token/create" {
  capabilities = ["create", "update"]
}

path "auth/token/create-orphan" {
  capabilities = ["create"]
}
```