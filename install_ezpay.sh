#!/bin/bash

echo "🚀 开始安装 EzPay 聚合支付系统..."

# ====== 基础变量 ======
INSTALL_DIR="/www/wwwroot/ezpay"
DATA_DIR="/www/wwwroot/ezpay_data"
PORT=6088

# ====== 安装依赖 ======
echo "📦 安装基础依赖..."
yum install -y git wget curl || apt update && apt install -y git wget curl

# ====== 安装 Go ======
if ! command -v go &> /dev/null
then
    echo "⬇️ 安装 Go 1.21..."
    cd /usr/local
    wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
    tar -xzf go1.21.6.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    source /etc/profile
fi

go version

# ====== 下载源码 ======
echo "📥 下载 EzPay..."
cd /www/wwwroot
rm -rf ezpay
git clone https://github.com/opinework/ezpay.git
cd ezpay

# ====== 编译 ======
echo "⚙️ 编译程序..."
make release

# ====== 创建数据目录 ======
mkdir -p $DATA_DIR

# ====== 生成配置文件 ======
echo "📝 生成配置文件..."
cp config.yaml.example config.yaml

cat > config.yaml <<EOF
server:
  port: $PORT

database:
  host: 127.0.0.1
  port: 3306
  user: ezpay
  password: 123456
  dbname: ezpay

storage:
  data_dir: "$DATA_DIR"
EOF

# ====== 创建 systemd 服务 ======
echo "⚙️ 配置开机启动..."

cat > /etc/systemd/system/ezpay.service <<EOF
[Unit]
Description=EzPay Service
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/release/ezpay-linux-amd64
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ezpay
systemctl restart ezpay

# ====== 开放端口 ======
echo "🔥 开放端口..."
firewall-cmd --add-port=$PORT/tcp --permanent 2>/dev/null
firewall-cmd --reload 2>/dev/null

# ====== 完成 ======
echo ""
echo "✅ 安装完成！"
echo "👉 访问地址: http://你的IP:$PORT"
echo "👉 默认账号: admin / admin123"
echo ""
echo "⚠️ 请务必："
echo "1. 修改数据库密码"
echo "2. 宝塔创建数据库 ezpay"
echo "3. 配置域名反向代理"
