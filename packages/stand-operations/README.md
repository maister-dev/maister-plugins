# Stand maintenance

Requires MAIster engine 3.12.0 or later and a configured Linux stand helper.

1. Install the package at an immutable Git tag and confirm the resolved commit. Review and trust that revision.
2. Create reviewed company bindings for `stand-operations:coordinator` and `stand-operations:diagnostic`. Pin the coordinator to `stand-maintenance` and assign a ready Claude ACP runner. Grant the diagnostic role read-only assignment, target, logs and knowledge access. Give restart authority to the coordinator only for the pilot and retain the required human approval.
3. Submit a company assignment naming the configured stand and component, and required effect and health evidence. The configured target supplies the exact runbook pin. Keep the requester's current target and source grants in place.
4. Review the operation ID and exact request digest in the approval control. Approve only the intended component and revision. After recording approval, continue the authorization step in Inbox. A clarification about missing information changes the input before any operation intent is retained.
5. After a timeout, reconcile the original operation. An unknown effect retains resource exclusion. An authorized operator can inspect it and decide whether to hold or authorize a new intent. A successor needs its own approval. Inspect the independently retained health result before accepting the assignment.
6. Review any proposed Brain addition separately. An accepted assignment does not confirm the assertion.

# Обслуживание стенда

Требуются движок MAIster 3.12.0 или новее и настроенный Linux-помощник стенда.

1. Установите пакет по неизменяемому Git-тегу и проверьте коммит. Проверьте и отметьте доверенной именно эту ревизию.
2. Создайте проверенные привязки компании для `stand-operations:coordinator` и `stand-operations:diagnostic`. Закрепите `stand-maintenance` за координатором и назначьте готовый Claude ACP runner. Диагносту нужны права чтения задания, цели, журналов и знаний. Право рестарта выдайте координатору для пилота и сохраните обязательное одобрение человека.
3. Создайте задание компании. Укажите настроенный стенд и компонент, точная ревизия инструкции и свидетельство определяются настройками цели. Укажите, что для принятия требуются подтверждённый эффект и проверка здоровья. У инициатора должны действовать права на цель и источники.
4. Проверьте ID операции и точный digest запроса в форме одобрения. Одобрите только нужный компонент и ревизию. После записи одобрения продолжите шаг авторизации во «Входящих». Уточнение недостающих данных изменяет входные данные до создания операции.
5. После таймаута сверьте исходную операцию. Неизвестный эффект сохраняет блокировку ресурса. Уполномоченный оператор может осмотреть состояние и решить, оставить блокировку или разрешить новую операцию. У новой операции своё одобрение. Перед принятием задания проверьте отдельно сохранённый результат проверки здоровья.
6. Рассматривайте предложение в Brain отдельно. Принятие задания само по себе не подтверждает утверждение.
