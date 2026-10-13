#!/bin/sh
# Uso: pix-patch.sh <raiz do invoiceninja>
set -e
R="$1"
F="$R/app/Models/PaymentType.php"
sed -i "/'payment_type_Zelle'/a\    'payment_type_PIX' => 'PIX'," "$R"/lang/*/texts.php
sed -i "/self::PROMPTPAY => 'payment_type_PromptPay',/a\        200 => 'payment_type_PIX'," "$F"
sed -i "/\['id' => 54, 'name' => 'PromptPay', 'gateway_type_id' => 31\],/a\            ['id' => 200, 'name' => 'PIX', 'gateway_type_id' => null]," "$F"
grep -q "payment_type_PIX" "$R/lang/pt_BR/texts.php"
grep -q "200 => 'payment_type_PIX'" "$F"
grep -q "'id' => 200, 'name' => 'PIX'" "$F"
php -l "$F" >/dev/null
