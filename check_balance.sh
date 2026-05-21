#!/bin/bash
API_KEY="sk-e2ef86a0ff23458f9ac5f274cc95f7d4"
THRESHOLD=5.0
GATEWAY_TOKEN="68a213e27217bc032e2339d81e55cf7a"
WEIXIN_TARGET="o9cq802F1ke6f6E8jqqtnjfsklaw@im.wechat"

BALANCE_RAW=$(curl -s --connect-timeout 10 https://api.deepseek.com/user/balance \
  -H "Authorization: Bearer $API_KEY")

BALANCE=$(echo "$BALANCE_RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['balance_infos'][0]['total_balance'])")
AVAILABLE=$(echo "$BALANCE_RAW" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['is_available'])")

if [ -z "$BALANCE" ] || [ "$AVAILABLE" != "True" ]; then
  OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" /usr/bin/openclaw message send \
    --channel openclaw-weixin --target "$WEIXIN_TARGET" \
    --message "⚠️ DeepSeek API 余额查询失败，请检查！" 2>/dev/null
  exit 1
fi

SEND_MSG=""
ALERT_LABEL=""
if python3 -c "exit(0 if float('$BALANCE') < 1.0 else 1)" 2>/dev/null; then
  SEND_MSG="🚨 DeepSeek API 余额即将耗尽！当前仅剩：¥${BALANCE}，再不充值小梦就要休眠了😢"
  ALERT_LABEL="CRITICAL"
elif python3 -c "exit(0 if float('$BALANCE') < $THRESHOLD else 1)" 2>/dev/null; then
  SEND_MSG="⚠️ DeepSeek API 余额不足预警！当前余额：¥${BALANCE}，阈值：¥${THRESHOLD}，请及时充值🥺"
  ALERT_LABEL="WARNING"
fi

if [ -n "$SEND_MSG" ]; then
  OPENCLAW_GATEWAY_TOKEN="$GATEWAY_TOKEN" /usr/bin/openclaw message send \
    --channel openclaw-weixin --target "$WEIXIN_TARGET" \
    --message "$SEND_MSG" 2>/dev/null
  echo "Alert sent: $ALERT_LABEL (¥$BALANCE)"
else
  echo "Balance OK: ¥$BALANCE"
fi
