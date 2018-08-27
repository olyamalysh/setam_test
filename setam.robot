*** Settings ***
Library  Selenium2Library
Library  BuiltIn
Library  Collections
Library  String
Library  DateTime
Library  setam_service.py

*** Variables ***

*** Keywords ***

Підготувати клієнт для користувача
    [Arguments]  ${username}
    ${chrome_options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
#   Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}
    Run Keyword If  '${USERS.users['${username}'].browser}' in 'Chrome chrome'  Run Keywords
    ...  Call Method  ${chrome_options}  add_argument  --headless
    ...  AND  Create Webdriver  Chrome  alias=my_alias  chrome_options=${chrome_options}
    ...  AND  Go To  ${USERS.users['${username}'].homepage}
    ...  ELSE  Open Browser  ${USERS.users['${username}'].homepage}  ${USERS.users['${username}'].browser}  alias=my_alias
    Set Window Size  ${USERS.users['${username}'].size[0]}  ${USERS.users['${username}'].size[1]}
    Run Keyword If  'Viewer' not in '${username}'  Run Keywords
    ...  Авторизація  ${username}
    ...  AND  Run Keyword And Ignore Error  Закрити Модалку


Підготувати дані для оголошення тендера
    [Arguments]  ${username}  ${initial_tender_data}  ${role}
    ${tender_data}=  prepare_tender_data  ${role}  ${initial_tender_data}
    [Return]  ${tender_data}

Авторизація
    [Arguments]  ${username}
    Click Element  xpath=//a[contains(@href,"login")][contains(text(),"Увiйти")]
    Input Text  xpath=//*[@id="loginformverifycode-username"]  ${USERS.users['${username}'].login}
    Input Text  xpath=//*[@id="loginformverifycode-password"]  ${USERS.users['${username}'].password}
    Click Element  xpath=//*[@id="login-form"]/div/div[3]/button



Створити об'єкт МП
    [Arguments]  ${username}  ${tender_data}

    Click Element  xpath=//button[@data-target="#toggleRight"]/span[contains(@class, "glyphicon-user")]
    Wait Until Element Is Visible  xpath=//a[contains(@href,"buyer/assets/index")][contains(text(),"Мої об’єкти")]
    Click Element  xpath=//a[contains(@href,"buyer/assets/index")][contains(text(),"Мої об’єкти")]
    Click Element  xpath=//a[contains(@href,"buyer/asset/create")][contains(text(),"Створити об’єкт")]
    Input Text  name=Asset[title]  ${tender_data.data.title}
    Input Text  name=Asset[description]  ${tender_data.data.description}
    ${decision_date}=  convert_date_for_decision  ${tender_data.data.decisions[0].decisionDate}
    Input Text  id=decision-0-title  ${tender_data.data.decisions[0].title}
    Input Text  id=decision-0-decisionid  ${tender_data.data.decisions[0].decisionID}
    Input Text  id=decision-0-decisiondate  ${decision_date}
    Click Element  id=assetHolder-checkBox
    Input Text  id=organization-assetholder-name  ${tender_data.data.assetHolder.name}
    Input Text  id=identifier-assetholder-id  ${tender_data.data.assetHolder.identifier.id}
    ${items}=  Get From Dictionary  ${tender_data.data}  items
    ${items_length}=  Get Length  ${items}
    :FOR  ${item}  IN RANGE  ${items_length}
    \  Run Keyword If  ${item}>0  Scroll To And Click Element  id=add-item-to-asset
    \  Додати Предмет МП  ${items[${item}]}
    Select From List By Index  id=contact-point-select  1
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")]
    ${tender_uaid}=  Get Text  xpath=//div[contains(@data-test-id, "tenderID")]
    [Return]  ${tender_uaid}


Додати предмет МП
    [Arguments]  ${item_data}
    ${item_number}=  Get Element Attribute  xpath=(//div[contains(@class, "asset-item") and not (contains(@class, "__empty__"))])[last()]@class
    ${item_number}=  Set Variable  ${item_number.split('-')[-1]}
    Input Text  id=asset-${item_number}-description  ${item_data.description}
    Convert Input Data To String  id=asset-${item_number}-quantity  ${item_data.quantity}
    Select From List By Value  id=unit-${item_number}-code  ${item_data.unit.code}
    #Select From List By Label  xpath=//div[contains (@class, "field-wrapper field-unit-${item_number}-name")]/../descendant::select[@id="classification-scheme"]  ${item_data.classification.scheme}
    Click Element  id=classification-${item_number}-description
    Wait Until Element Is Visible  id=search_code
    Input Text  id=search_code  ${item_data.classification.id}
    Wait Until Element Is Visible  xpath=//span[@class="item-id"][contains (text(),"${item_data.classification.id}")]
    Click Element  xpath=//span[@class="item-id"][contains (text(),"${item_data.classification.id}")]
    Click Element  id=btn-ok
    Wait Until Element Is Not Visible  xpath=//*[@class="fade modal"]
    Select From List By Value  id=address-${item_number}-countryname  ${item_data.address.countryName}
    Select From List By Label  id=address-${item_number}-region  ${item_data.address.region}
    Input Text  id=address-${item_number}-locality  ${item_data.address.locality}
    Input Text  id=address-${item_number}-streetaddress  ${item_data.address.streetAddress}
    Input Text  id=address-${item_number}-postalcode  ${item_data.address.postalCode}
    Select From List By Value  name=Asset[items][${item_number}][registrationDetails][status]  ${item_data.registrationDetails.status}


Оновити сторінку з об'єктом МП
    [Arguments]  ${username}  ${tender_uaid}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}


Пошук об’єкта МП по ідентифікатору
    [Arguments]  ${username}  ${tender_uaid}
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Click Element  xpath=//a[contains(@href,"http://eauction-dev.byustudio.in.ua/assets/index")]
    Wait Until Element Is Visible  xpath=//div[contains (@class, "field-assetssearch-asset_cbd_id")]
    Input Text  xpath=//input[contains(@id, "assetssearch-asset_cbd_id")]   ${tender_uaid}
    Click Element  xpath=//button[contains(@class, "btn-search mk-btn mk-btn_accept")]
    #Wait Until Element Is Visible  xpath=//div[contains(@class, "search-result_t")][contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${tender_uaid}")]/../../div[2]/a[contains(@href, "/asset/view")]
    ...  AND  Wait Until Element Is Not Visible  xpath=//button[contains(text(), "Шукати")]  10
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]


Завантажити документ для видалення об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  id=delete-asset
    Wait Until Element Is Visible  xpath=//div[contains(@class,"text-center")][contains(text(),"Підтвердіть видалення!!!")]
    Choose File  name=FileUpload[file][]  ${file_path}
    Wait Until Keyword Succeeds  30 x  10 s  Wait Until Element Is Visible  xpath=//input[contains(@class, "file_original_name")]
    Capture Page Screenshot
    Click Element  xpath=//button[contains(@type, "submit")]
    Capture Page Screenshot
    #Wait Until Element Is Not Visible  xpath=//div[contains(@class, "modal-dialog modal-lg")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Page Contains Element  xpath=//div[contains(@class, "alert-success alert fade in")]
    Capture Page Screenshot
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Element Is Visible  xpath=//div[contains(text(), "Об’єкт виключено")]


Видалити об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}


Отримати інформацію із об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${field}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Run Keyword If  'title' in '${field}'  Execute Javascript  $("[data-test-id|='title']").css("text-transform", "unset")
    ${field_value}=  Run Keyword If  '${field}' == 'status'  Get Element Attribute  xpath=//*[@id="asset_status"]@value
    ...  ELSE IF  '${field}' == 'assetID'  Get Text  xpath=//div[contains(@data-test-id, "tenderID")]
    ...  ELSE IF  '${field}' == 'description'  Get Text  xpath=//div[@data-test-id ="item.description"]
    ...  ELSE IF  'decision' in '${field}'  Отримати інформацію про asset_decisions  ${field}
    ...  ELSE IF  '${field}' == 'documents[0].documentType'  Get Text  xpath=//*[contains(text(),"Інформація про оприлюднення інформаційного повідомлення")]
#    ...  ELSE IF  '${field}' == 'classification.scheme'  Get Text
#    ...  ELSE IF  '${field}' == 'classification.idclas'  Get Text
#    ...  ELSE IF  '${field}' == 'unit.name'  Get Text
#    ...  ELSE IF  '${field}' == 'quantity'  Get Text
#    ...  ELSE IF  '${field}' == 'registrationDetails.status'  Get Text
    ...  ELSE  Get Text  xpath=//*[@data-test-id ="${field}"]
    ${field_value}=  adapting_date_for_at  ${field}  ${field_value}
    [Return]  ${field_value}


Отримати інформацію про asset_decisions
    [Arguments]  ${field}
    ${index_number}=  Set Variable  ${field.split('[')[-1].split(']')[0]}
    ${index_number}=  Convert To Integer  ${index_number}
    ${value}=  Run Keyword If  'title' in '${field}'  Get Text  xpath=//div[@data-test-id ="asset.decision.title"][${index_number+1}]
    ...  ELSE IF  'decisionDate' in '${field}'  Get Text  xpath=//div[@data-test-id ="asset.decision.decisionDate"][${index_number+1}]
    ...  ELSE IF  'decisionID' in '${field}'  Get Text  xpath=//div[@data-test-id ="asset.decision.decisionID"][${index_number+1}]
    [Return]  ${value}


Отримати інформацію з активу об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${object_id}  ${field}
    ${item_value}=  Run Keyword If  'description' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}")]
    ...  ELSE IF  'classification.scheme' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}" )]/../following-sibling::div/descendant::div[contains(text(), "Класифікація згідно")]
    ...  ELSE IF  'classification.id' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}" )]/../following-sibling::div/descendant::span[@data-test-id="item.classification.id"]
    ...  ELSE IF  'unit.name' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}" )]/../following-sibling::div/descendant::span[@data-test-id="item.unit.name"]
    ...  ELSE IF  'quantity' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}" )]/../following-sibling::div/descendant::span[@data-test-id="item.quantity"]
    ...  ELSE IF  'registrationDetails.status' in '${field}'  Get Text  xpath=//div[contains(text(), "${object_id}" )]/../following-sibling::div/descendant::div[@data-test-id="item.address.status"]
    ${item_value}=  adapting_date_from_item  ${field}  ${item_value}
    [Return]  ${item_value}


Завантажити ілюстрацію в об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(text(), "Редагувати об’єкт")]
    Scroll To And Click Element  xpath=//div[@id="documents-container"]/following-sibling::div/descendant::button[1]
    Wait Until Element Is Visible  xpath=//div[@id="documents-container"]/following-sibling::div/descendant::div[contains(text()," Додати документ")]
    Choose File  name=FileUpload[file]  ${file_path}
    Sleep  3
    ${document_number}=  Get Element Attribute  xpath=(//input[contains(@class,"document-title") and not (contains(@name,"__empty__"))])[last()]@id
    ${document_number}=  Set Variable  ${document_number.split('-')[-2]}
    Select From List By Value  id=document-${document_number}-documenttype  illustration
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Завантажити документ в об'єкт МП з типом
    [Arguments]  ${username}  ${tender_uaid}  ${file_path}  ${doc_type}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(text(), "Редагувати об’єкт")]
    Scroll To And Click Element  xpath=//div[@id="documents-container"]/following-sibling::div/descendant::button[1]
    Wait Until Element Is Visible  xpath=//div[@id="documents-container"]/following-sibling::div/descendant::div[contains(text()," Додати документ")]
    Choose File  name=FileUpload[file]  ${file_path}
    Sleep  3
    ${document_number}=  Get Element Attribute  xpath=(//input[contains(@class,"document-title") and not (contains(@name,"__empty__"))])[last()]@id
    ${document_number}=  Set Variable  ${document_number.split('-')[-2]}
    Select From List By Value  id=document-${document_number}-documenttype  ${doc_type}
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10


Внести зміни в об'єкт МП
    [Arguments]  ${username}  ${tender_uaid}  ${field}  ${value}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(text(), "Редагувати об’єкт")]
    Run Keyword If  '${field}' == 'title'  Input Text  name=Asset[title]  ${value}
    ...  ELSE IF  '${field}' == 'description'  Input Text  name=Asset[description]  ${value}
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]


Додати актив до об'єкта МП
    [Arguments]  ${username}  ${tender_uaid}  ${item_data}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(text(), "Редагувати об’єкт")]
    Scroll To And Click Element  id=add-item-to-asset
    Додати предмет МП  ${item_data}
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]


Внести зміни в актив об'єкта МП
    [Arguments]  ${username}  ${object_id}  ${tender_uaid}  ${field}  ${value}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[contains(text(), "Редагувати об’єкт")]
    ${value}=  Convert To String  ${value}
    Input Text  xpath=//textarea[contains(text(),"${object_id}")]/../../following-sibling::div/descendant::input[contains(@id, "quantity")]  ${value}
    Scroll To And Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "tenderID")][contains(text(), "${tender_uaid}")]


Отримати кількість активів в об'єкті МП
    [Arguments]  ${username}  ${tender_uaid}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    ${count_of_items}=  Get Matching Xpath Count  xpath=//div[@data-test-id="asset.item.description"]
    ${count_of_items}=  Convert To Integer  ${count_of_items}
    [Return]  ${count_of_items}


Отримати документ
    [Arguments]  ${username}  ${TENDER['TENDER_UAID']}  ${doc_id}
    ${file_name}=  Get Text  xpath=//a[contains(text(), '${doc_id}')]
    ${url}=  Get Element Attribute  xpath=//a[contains(text(), '${doc_id}')]@href
    download_file  ${url}  ${file_name}  ${OUTPUT_DIR}
    [Return]  ${file_name}


Scroll To And Click Element
    [Arguments]  ${locator}
    ${y}=  Get Vertical Position  ${locator}
    Execute JavaScript    window.scrollTo(0,${y-100})
    Click Element  ${locator}


Закрити Модалку
    ${status}=  Run Keyword And Return Status  Wait Until Element Is Visible  xpath=//button[@data-dismiss="modal"]  5
    Run Keyword If  ${status}  Wait Until Keyword Succeeds  3 x  1 s  Run Keywords
    ...  Click Element  xpath=//button[@data-dismiss="modal"]
    ...  AND   Wait Until Element Is Not Visible  xpath=//*[contains(@class, "modal-backdrop")]


Convert Input Data To String
    [Arguments]  ${locator}  ${value}
    ${value}=  Convert To String  ${value}
    Input Text  ${locator}  ${value}



# С'ютік для лотіка :)

Створити лот
    [Arguments]  ${username}  ${item_data}  ${tender_uaid}
    setam.Пошук об’єкта МП по ідентифікатору  ${username}  ${tender_uaid}
    Click Element  xpath=//a[@class="mk-btn mk-btn_default"][text()="Створити інформаційне повідомлення"]
    Wait Until Element Is Visible  xpath=//div[text()="Рішення про приватизацію об’єкту/затвердження умов продажу об’єкта"]
    ${new_date_for_lots_decision}=  convert_date_for_decision  ${item_data.data.decisions[0].decisionDate}
    Input Text  id=decision-decisionid  ${item_data.data.decisions[0].decisionID}
    Input Text  id=decision-decisiondate  ${new_date_for_lots_decision}
    Click Element  id=btn-submit-form
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "lotID")]
    ${lot_id}=  Get Text  xpath=//div[contains(@data-test-id, "lotID")]
    [Return]  ${lot_id}


Додати умови проведення аукціону
    [Arguments]  ${username}  ${item_data}  ${index_auction}  ${lot_id}
    Run Keyword If  ${index_auction} == 0  Заповнити дані для першого аукціону  ${item_data}
    Capture Page Screenshot
    Run Keyword If  ${index_auction} == 1  Заповнити дані для другого аукціону  ${item_data}
    Capture Page Screenshot


Заповнити дані для першого аукціону
    [Arguments]  ${item_data}
    ${minimalStep}=  Convert To String  ${item_data.minimalStep.amount}
    ${guarantee_amount}=  Convert To String  ${item_data.guarantee.amount}
    ${value}=  Convert To String  ${item_data.value.amount}
    ${date_from_auction}=  convert_date_for_auction  ${item_data.auctionPeriod.startDate}
    Click Element  xpath=//a[@class="mk-btn mk-btn_default"]
    Click Element  id=auctions-checkBox
    Wait Until Element Is Visible  xpath=//div[@class="panel-heading"][contains(text(), "Аукціон із зниженням стартової ціни")]
    Input Text  xpath=//input[@id="value-value-0-amount"]  ${value}
    Input Text  xpath=//input[@id="value-minimalstep-0-amount"]  ${minimalStep}
    Input Text  xpath=//input[@id="guarantee-guarantee-0-amount"]  ${guarantee_amount}
    Input Text  xpath=//input[@id="period-0-startdate"]  ${date_from_auction}
    Input Text  xpath=//input[@id="bankaccount-bankaccount-0-bankname"]  ${item_data.bankAccount.bankName}
    Input Text  xpath=//input[@id="identification-bankaccount-0-0-id"]  ${item_data.bankAccount.accountIdentification[0].id}
    Input Text  xpath=//input[@id="identification-bankaccount-0-1-id"]  000000
    Input Text  xpath=//input[@id="identification-bankaccount-0-2-id"]  0000000000000000


Заповнити дані для другого аукціону
    [Arguments]  ${item_data}
    ${duration}=  convert_duration  ${item_data.tenderingDuration}
    Input Text  xpath=//input[@id="auction-1-tenderingduration"]  ${duration}
    Click Element  xpath=//button[@id="btn-submit-form"]
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "lotID")]
    Click Element  xpath=//a[@class="mk-btn mk-btn_accept js-btn-verification"]
    Wait Until Element Is Visible  xpath=//div[@class="alert-success alert fade in"]
#    Wait Until Keyword Succeeds  5 x  10 s  Run Keywords
#    ...  Reload Page
#    ...  AND  Wait Until Page Does Not Contain   Перевірка доступності об’єкту  10
    Capture Page Screenshot



Пошук лоту по ідентифікатору
    [Arguments]  ${username}  ${lot_id}
    Go To  ${USERS.users['${username}'].homepage}
    Sleep  3
    Закрити Модалку
    Click Element  xpath=//a[contains(@href, "http://eauction-dev.byustudio.in.ua/lots/index")]
    Wait Until Element Is Visible  xpath=//input[contains(@id, "lotssearch-lot_cbd_id")]
    Input Text  xpath=//input[contains(@id, "lotssearch-lot_cbd_id")]  ${lot_id}
    Click Element  xpath=//button[contains(@class, "btn-search mk-btn mk-btn_accept")]
    Wait Until Keyword Succeeds  10 x  1 s  Wait Until Element Is Visible  xpath=//div[@class="search-result_t"][contains(text(), "${lot_id}")]
    Wait Until Keyword Succeeds  20 x  3 s  Run Keywords
    ...  Click Element  xpath=//div[@class="search-result"]/descendant::div[contains(text(), "${lot_id}")]/../../div[2]/a[contains(@href, "/lot/view")]
    ...  AND  Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "lotID")]
    Закрити Модалку
    Wait Until Element Is Visible  xpath=//div[@data-test-id="lotID"]


Отримати інформацію із лоту
    [Arguments]  ${username}  ${lot_id}  ${field}
    setam.Оновити сторінку з лотом  ${username}  ${lot_id}
    ${field_in_lot}=  Run Keyword If  '${field}' == 'status'  Get Text  xpath=//div[@data-test-id="status"]
    ${field_in_lot}=  adapting_date_for_at  ${field}  ${field_in_lot}
    [Return]  ${field_in_lot}

Оновити сторінку з лотом
    [Arguments]  ${username}  ${lot_id}
    setam.Пошук лоту по ідентифікатору  ${username}  ${lot_id}


Видалити лот
    [Arguments]  ${username}  ${lot_id}
    setam.Пошук лоту по ідентифікатору  ${username}  ${lot_id}
    Wait Until Element Is Visible  id=delete_btn
    Click Element  id=delete_btn

    Wait Until Element Is Visible  xpath=//h4[contains(@class, "modal-title")]
    Click Element  xpath=//button[contains(@class, "btn mk-btn mk-btn_accept")]
    Wait Until Element Is Visible  xpath=//div[contains(@class, "message message_danger")]



Завантажити документ для видалення лоту
    [Arguments]  ${username}  ${lot_id}  ${file_path}
    setam.Оновити сторінку з лотом  ${username}  ${lot_id}
    #Wait Until Element Is Visible  xpath=//a[contains(@class,"mk-btn mk-btn_default")]
    Click Element  xpath=//a[contains(@class, "mk-btn mk-btn_default")]
    Wait Until Element Is Visible  id=ul-document-dropdown
    Click Element  id=ul-document-dropdown
    Wait Until Element Is Visible  id=add-document
    Choose File  name=FileUpload[file]  ${file_path}
    Sleep  3
    ${document_number}=  Get Element Attribute  xpath=(//input[contains(@class,"document-title") and not (contains(@name,"__empty__"))])[last()]@id
    ${document_number}=  Set Variable  ${document_number.split('-')[-2]}
    Select From List By Value  id=document-${document_number}-documenttype  cancellationDetails
    Click Element  id=btn-submit-form
    Sleep  3
    Wait Until Element Is Visible  xpath=//div[contains(@data-test-id, "lotID")]
    Wait Until Keyword Succeeds  30 x  10 s  Run Keywords
    ...  Reload Page
    ...  AND  Wait Until Page Does Not Contain   Документ завантажується...  10