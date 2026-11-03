# 2026 FNC BAND KINGDOM 應援物交換/領取平台 — 表格版 1.1

## 本次版本
- 版面最大寬度 1024px，移除海報、大型宣傳標語和英文品牌標頭。
- 列表皆為表格，手機左右滑動，不轉成卡片。
- 福利交換、飯製應援領取各自獨立列表、欄位、篩選與發布表單，沒有混合列表。
- 官方福利只有 HI-TOUCH、SIGNED POSTER、SPECIAL POLAROID、GROUP PHOTO。移除 PHOTO CARD；飯製自製小卡仍可發布。
- 免註冊，不收 Email、電話、真實姓名。自訂暱稱和公開聯絡連結仍屬資訊收集，發布者需同意公開。
- 每則貼文產生私人管理連結，請自行保存；持有者能編輯、結束或刪除。遺失不提供帳號找回。
- 收藏與管理連結保存在本機瀏覽器。正式模式管理連結可跨裝置使用；本機模式資料僅限原瀏覽器。

## GitHub Pages
將此資料夾內檔案上傳 repository 根目錄，Settings → Pages → Deploy from a branch → main / (root)。所有路徑均為相對路徑。不需 npm 或編譯。
本機預覽可使用 VS Code Live Server 等 HTTP 伺服器，不要直接以 file:// 開啟。

## 共用資料庫
1. 建立 Supabase 專案，在 SQL Editor 執行本版 supabase.sql。
2. config.js 填 Project URL 與 publishable / anon 公開金鑰；不啟用 Email 登入、不需會員註冊。絕不可放 service_role 或 secret key。
3. 再上傳 GitHub。未填設定時是明確標示的本機試用；範例資料不是真實發放。正式模式不載入範例。
4. v1.1 使用新表 board_posts、board_keys，舊版 posts 不會被修改，也不會自動匯入。
5. RLS 僅允許公開讀取 board_posts。新增與管理透過 RPC；管理函式驗證私人金鑰雜湊，公開列表不可讀取金鑰表，不能直接更新或刪除。
6. 部署後須實測：兩個瀏覽器看見相同貼文、有效管理連結能修改、錯誤金鑰無法修改、anon 無法讀取 board_keys 或直接寫入 board_posts。本地環境尚未連線你的 Supabase，因此 SQL 和共用模式尚未實際部署驗證。

## 限制
尚無驗證碼、防洗版限流、檢舉、站內管理後台；免註冊 RPC 新增開放匿名呼叫，大規模公開前需加服務端反濫用機制。管理者目前在 Supabase Table Editor 下架違規貼文。
圖片使用公開網址，僅顯示於詳情，不提供檔案上傳。貼文兩天共用一個整體狀態，時間地點請分別註明。平台無站內聊天、預約扣庫存、推播或離線功能。Web App Manifest 可供加入主畫面，仍需網路。

## UI 元件
Lucian UX/UI Prompt #039 Sliding pill tabs：福利交換／飯製應援領取切換。保留來源 CSS 與 MIT 授權，適配中文、資料篩選及自適應寬度。其他舊元件來源樣式保留但不再使用。支援深淺色、左右鍵切換、減少動畫。
https://lucianlabs.dev/uxui-prompt/#039

## 驗證
已用 Edge 無頭瀏覽器檢查：兩區表格、不含卡片/登入/PHOTO CARD、兩區發布、編輯、完成狀態、私人管理連結重開、375px 無頁面水平溢出、深淺色、鍵盤分頁與減少動畫。Supabase 實際環境尚未測試。

## 1.3 發布表單分離
福利交換與飯製應援使用獨立的欄位模板，不共用混合表單。交換有持有福利、想換福利與各自場次；飯製有應援物名稱、照片、發放時間地點與領取條件。發布按鈕隨目前區塊切換名稱，發布類型不可自行跨區變更。
