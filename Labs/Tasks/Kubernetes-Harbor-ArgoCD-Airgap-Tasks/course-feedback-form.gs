/**
 * Mid-Course Feedback Form Generator
 * Software Development / DevOps Course
 *
 * HOW TO USE:
 * 1. Go to https://script.google.com
 * 2. Click "New Project"
 * 3. Paste this entire script
 * 4. Click Run → createFeedbackForm
 * 5. Approve permissions when prompted
 * 6. Check your Google Drive for the new form
 */

function createFeedbackForm() {
  // Create the form
  var form = FormApp.create('משוב אמצע קורס – פיתוח תוכנה / DevOps');
  form.setDescription(
    'תודה שאתם לוקחים כמה דקות למלא את השאלון.\n' +
    'המשוב שלכם עוזר לי לשפר את הקורס עבורכם ועבור קורסים עתידיים.\n' +
    'הטופס אנונימי לחלוטין.'
  );
  form.setCollectEmail(false);
  form.setConfirmationMessage('תודה רבה על המשוב! התשובות שלך יעזרו לשפר את הקורס.');

  // ─── Section 1: קצב ורמת הקורס ───────────────────────────────────────────
  form.addSectionHeaderItem()
    .setTitle('קטע 1: קצב ורמת הקורס');

  form.addScaleItem()
    .setTitle('כיצד תדרגו את קצב הקורס?')
    .setBounds(1, 5)
    .setLabels('מהיר מדי', 'איטי מדי')
    .setRequired(true);

  form.addScaleItem()
    .setTitle('כיצד תדרגו את רמת הקושי של החומר?')
    .setBounds(1, 5)
    .setLabels('קל מדי', 'קשה מדי')
    .setRequired(true);

  form.addScaleItem()
    .setTitle('עד כמה ברורים ההסברים של המרצה?')
    .setBounds(1, 5)
    .setLabels('לא ברורים בכלל', 'ברורים מאוד')
    .setRequired(true);

  // ─── Section 2: איכות החומר ───────────────────────────────────────────────
  form.addPageBreakItem()
    .setTitle('קטע 2: איכות החומר');

  var gridItem = form.addGridItem()
    .setTitle('דרגו את המרכיבים הבאים')
    .setRows([
      'המצגות / סליידים',
      'התרגילים המעשיים',
      'הדגמות הקוד / demos',
      'החומר הכתוב / תיעוד'
    ])
    .setColumns(['1 – גרוע', '2', '3', '4', '5 – מצוין'])
    .setRequired(true);

  // ─── Section 3: מעורבות ומוטיבציה ────────────────────────────────────────
  form.addPageBreakItem()
    .setTitle('קטע 3: מעורבות ומוטיבציה');

  form.addScaleItem()
    .setTitle('עד כמה אתם מרגישים מעורבים בשיעורים?')
    .setBounds(1, 5)
    .setLabels('בכלל לא', 'מאוד')
    .setRequired(true);

  form.addScaleItem()
    .setTitle('עד כמה אתם מרגישים בטוחים ביכולת שלכם ליישם את החומר?')
    .setBounds(1, 5)
    .setLabels('בכלל לא בטוח', 'בטוח מאוד')
    .setRequired(true);

  form.addCheckboxItem()
    .setTitle('מה עוזר לכם ללמוד הכי טוב? (ניתן לבחור יותר מאחד)')
    .setChoiceValues([
      'הדגמות מעשיות (live coding)',
      'תרגילים עצמאיים',
      'דיון קבוצתי',
      'חומר כתוב / תיעוד',
      'סרטונים קצרים'
    ])
    .showOtherOption(true)
    .setRequired(false);

  // ─── Section 4: שיפורים לשארית הקורס ────────────────────────────────────
  form.addPageBreakItem()
    .setTitle('קטע 4: שיפורים לשארית הקורס');

  form.addMultipleChoiceItem()
    .setTitle('מה הדבר הכי חשוב לשפר בשארית הקורס?')
    .setChoiceValues([
      'יותר תרגול מעשי',
      'הסברים מעמיקים יותר',
      'קצב איטי יותר',
      'יותר זמן לשאלות ותשובות',
      'חומר עדכני יותר'
    ])
    .showOtherOption(true)
    .setRequired(false);

  form.addParagraphTextItem()
    .setTitle('מה הדבר שהכי עזר לכם עד כה בקורס?')
    .setRequired(false);

  form.addParagraphTextItem()
    .setTitle('יש נושא שהייתם רוצים שנכסה יותר לעומק?')
    .setRequired(false);

  form.addParagraphTextItem()
    .setTitle('הערות נוספות / דברים שרציתם לשתף')
    .setRequired(false);

  // ─── Print results ────────────────────────────────────────────────────────
  var formUrl = form.getPublishedUrl();
  var editUrl = form.getEditUrl();

  Logger.log('✅ Form created successfully!');
  Logger.log('📋 Published URL (share with students): ' + formUrl);
  Logger.log('✏️  Edit URL: ' + editUrl);

  // Show a popup with the links
  var ui = SpreadsheetApp.getUi ? SpreadsheetApp.getUi() : null;
  Browser.msgBox(
    'הטופס נוצר בהצלחה! ✅\n\n' +
    'קישור לשיתוף עם הסטודנטים:\n' + formUrl + '\n\n' +
    'הטופס נשמר גם ב-Google Drive שלך.'
  );
}
