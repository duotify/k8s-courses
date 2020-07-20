### Host-based routing

- nginx.domain.com -> All nginx Pods
- nginx-v1.domain.com -> Pod nginx-v1
- nginx-v2.domain.com -> Pod nginx-v2
- nginx-v3.domain.com -> Pod nginx-v3



```
                                   +------------------+
       nginx-v1.domain.com         |                  |
 --------------------------------> |   Pod nginx v1   |  <------+
                                   |                  |         |
                                   +------------------+         |
                                                                |
                                   +------------------+         |
       nginx-v2.domain.com         |                  |         |       nginx.domain.com
 --------------------------------> |   Pod nginx v2   |  <----------------------------------+
                                   |                  |         |
                                   +------------------+         |
                                                                |
                                   +------------------+         |
       nginx-v3.domain.com         |                  |         |
 --------------------------------> |   Pod nginx v3   |  <------+
                                   |                  |
                                   +------------------+
```

