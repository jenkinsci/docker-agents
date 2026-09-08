#include <windows.h>
#include <ntsecapi.h>
#include <wchar.h>

int wmain(int argc, wchar_t **argv) {
    wchar_t *name = argc > 1 ? argv[1] : L"WORKGROUP";
    LSA_OBJECT_ATTRIBUTES oa = {0};
    LSA_HANDLE h;
    if (LsaOpenPolicy(0, &oa, POLICY_TRUST_ADMIN | POLICY_VIEW_LOCAL_INFORMATION, &h)) return 1;
    POLICY_PRIMARY_DOMAIN_INFO pd = {0};
    pd.Name.Buffer = name;
    pd.Name.Length = (USHORT)(wcslen(name) * 2);
    pd.Name.MaximumLength = pd.Name.Length + 2;
    return LsaSetInformationPolicy(h, PolicyPrimaryDomainInformation, &pd) ? 2 : 0;
}
