*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Desktop
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             XML
Library             RPA.Archive
Library             OperatingSystem


*** Variables ***
${GLOBAL_RETRY_AMOUNT}      10x
${GLOBAL_RETRY_INTERVAL}    0.5s

${DOWNLOAD_URL}             https://robotsparebinindustries.com/orders.csv
${URL}                      https://robotsparebinindustries.com/#/robot-order

${PDF_OUTPUT_DIR}           ${OUTPUT_DIR}${/}receipts${/}
${pdf}                      why html to pdf returns NONE!!!!


*** Tasks ***
Order robots from RobotSpareBinIndustries Inc
    Download order file
    @{orders}=    Get Orders
    Open the robot orders web
    Close the annoying modal
    Fill the form    ${orders}
    Create ZIP package from PDF files
    [Teardown]    Close Programs


*** Keywords ***
Download order file
    Download    ${DOWNLOAD_URL}    overwrite=${True}

Get Orders
    @{orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    @{orders}

Open the robot orders web
    Open Available Browser    ${URL}

Close the annoying modal
    Wait Until Element Is Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Select From List By Value    id:head    ${order}[Head]
        Click Button    id-body-${order}[Body]
        Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
        Input Text    id:address    ${order}[Address]
        Click Button    id:preview
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Make order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    id:order-another
        Close the annoying modal
    END

Make order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${fileName}
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf
    ...    ${order_results_html}
    ...    ${PDF_OUTPUT_DIR}${fileName}.pdf
    ...    overwrite=${True}
    ${pdf}=    Set Variable    ${PDF_OUTPUT_DIR}${fileName}.pdf
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${fileName}
    ${screenshot}=    Screenshot    id:robot-preview-image    filename=${OUTPUT_DIR}${/}screenshots${/}${fileName}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${screenshot}=    Create List    ${screenshot}:align=center
    Add Files To PDF    ${screenshot}    ${pdf}    append=True
    Close Pdf    ${pdf}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receips.zip
    Archive Folder With Zip
    ...    ${PDF_OUTPUT_DIR}
    ...    ${zip_file_name}

Close Programs
    Close Browser
