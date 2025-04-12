debian@hachimpocs:~/infra/pocs/traefik$ sudo ss -tuln | grep -E ':(80|443)'
tcp   LISTEN 0      4096            0.0.0.0:443        0.0.0.0:*          
tcp   LISTEN 0      4096            0.0.0.0:80         0.0.0.0:*          
tcp   LISTEN 0      4096               [::]:443           [::]:*          
tcp   LISTEN 0      4096               [::]:80            [::]:*   