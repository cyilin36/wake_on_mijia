# 1. 基础镜像
FROM python:3.9-slim

# 2. 设置工作目录
WORKDIR /app

# 3. 设置环境变量 (无缓冲输出日志)
ENV PYTHONUNBUFFERED=1

# 4. 安装系统依赖
# 必须安装 sshpass 和 openssh-client，否则 main.py 中的远程关机功能无法工作 [4]
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sshpass \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 5. 仅复制核心代码和默认配置
# 只要 main.py 和 config.ini 在同一目录，程序即可正常读取配置 [3]
COPY main.py config.ini /app/

# 6. 启动命令
CMD ["python3", "main.py"]