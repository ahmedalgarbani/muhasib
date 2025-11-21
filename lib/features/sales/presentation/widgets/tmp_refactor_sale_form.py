from pathlib import Path
import re

path = Path("lib/features/sales/presentation/widgets/sale_form.dart")
text = path.read_text(encoding="utf-8")

classes_to_remove = [
    "PrimaryButton",
    "SecondaryButton",
    "ItemCard",
    "_QuantityButton",
    "ExpandableSection",
    "_ExpandableSectionState",
    "EmptyState",
    "StickyInvoiceHeader",
    "StepIndicator",
    "CustomerBottomSheet",
    "_CustomerBottomSheetState",
    "AddItemBottomSheet",
    "_AddItemBottomSheetState",
    "SalesInvoiceScreen",
    "_SalesInvoiceScreenState",
    "Step1Customer",
    "_Step1CustomerState",
    "Step2Items",
    "_Step2ItemsState",
    "Step3Payment",
    "_Step3PaymentState",
    "Step4Review",
]


def remove_class_block(src: str, class_name: str) -> str:
    token = f"class {class_name}"
    while True:
        idx = src.find(token)
        if idx == -1:
            break
        start = idx
        while start > 0:
            prev_newline = src.rfind("\n", 0, start)
            segment = src[prev_newline + 1:start].strip()
            if segment.startswith("//") or segment == "":
                start = prev_newline + 1
                continue
            break
        brace_idx = src.find("{", idx)
        if brace_idx == -1:
            break
        depth = 0
        i = brace_idx
        while i < len(src):
            if src[i] == "{":
                depth += 1
            elif src[i] == "}":
                depth -= 1
                if depth == 0:
                    i += 1
                    break
            i += 1
        end = i
        while end < len(src) and src[end] in "\r\n \t":
            end += 1
        src = src[:start] + src[end:]
    return src


for name in classes_to_remove:
    text = remove_class_block(text, name)

if "library sale_form;" not in text:
    imports_start = text.find("import ")
    text = text[:imports_start] + "library sale_form;\n\n" + text[imports_start:]

parts = [
    'part "components/primary_button.dart";',
    'part "components/secondary_button.dart";',
    'part "components/item_card.dart";',
    'part "components/expandable_section.dart";',
    'part "components/empty_state.dart";',
    'part "components/sticky_invoice_header.dart";',
    'part "components/step_indicator.dart";',
    'part "components/customer_bottom_sheet.dart";',
    'part "components/add_item_bottom_sheet.dart";',
    'part "components/sales_invoice_screen.dart";',
    'part "components/step1_customer.dart";',
    'part "components/step2_items.dart";',
    'part "components/step3_payment.dart";',
    'part "components/step4_review.dart";',
]
parts_block = "\n".join(parts) + "\n\n"

match = re.search(r"(import\s+[^;]+;\s*)+", text)
if match:
    insert_pos = match.end()
    text = text[:insert_pos] + "\n" + parts_block + text[insert_pos:]

path.write_text(text, encoding="utf-8")
