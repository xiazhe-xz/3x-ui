#!/usr/bin/env bash
# 一键生成配置，手动输入域名

# 让用户输入域名
read -rp "请输入你的域名（如 live.zhexia.top）: " DOMAIN

# 检查是否输入了
if [ -z "$DOMAIN" ]; then
  echo "❌ 域名不能为空，已退出。"
  exit 1
fi

# 定义要写入的文件路径
CONFIG_PATH="/etc/sing-box/config.json"

# 创建目录（如果不存在）
mkdir -p "$(dirname "$CONFIG_PATH")"

# 写入 JSON，插入用户输入的域名
cat > "$CONFIG_PATH" << EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "address": "tls://8.8.8.8"
      }
    ]
  },
  "ntp": {},
  "endpoints": [],
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "0.0.0.0",
      "listen_port": 443,
      "up_mbps": 1000,
      "down_mbps": 1000,
      "obfs": {
        "type": "salamander",
        "password": "X4J97cgQz+slfih9Ks+U4g"
      },
      "users": [
        {
          "name": "sekai",
          "password": "C4ytxiWeQok3tWGu3oo6Lg"
        }
      ],
      "tls": {
        "enabled": true,
        "certificate_path": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
        "key_path": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "blocked"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "protocol": [
          "bittorrent"
        ],
        "outbound": "blocked"
      },
      {
        "geoip": [
          "private"
        ],
        "outbound": "direct"
      }
    ],
    "final": "direct"
  },
  "experimental": {}
}
EOF

echo "✅ 配置文件已生成: $CONFIG_PATH"
