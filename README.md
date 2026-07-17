# Let’s Dine — Complete Setup

Main Supabase project used: `oykzaktjjmfdhcxzamzo`.

## Files
- `index.html`: invitation + RSVP modal
- `admin.html`: secure guest management portal
- `verify.html`: QR verification page
- `config.js`: frontend Supabase settings
- `supabase.sql`: tables, RLS and functions
- `supabase/functions/send-rsvp-email/index.ts`: Resend email + unique QR

## Setup
1. Run all of `supabase.sql` in Supabase SQL Editor.
2. In Authentication > Users, create the admin email/password.
3. Copy the Auth user UUID and run:
```sql
insert into public.admin_users(user_id,full_name)
values('PASTE-AUTH-USER-UUID','Nico Event Admin');
```
4. Replace `https://YOUR-DOMAIN.com/verify.html` inside `config.js` with the real hosted verification URL.
5. Create a Resend account and verify your sending domain.
6. Deploy the function:
```bash
supabase login
supabase link --project-ref oykzaktjjmfdhcxzamzo
supabase functions deploy send-rsvp-email --no-verify-jwt
```
7. Add secrets:
```bash
supabase secrets set RESEND_API_KEY="re_your_key"
supabase secrets set FROM_EMAIL="Nico Invitations <invites@yourdomain.co.za>"
```
8. Upload `index.html`, `admin.html`, `verify.html`, and `config.js` to one web folder.

## Security
The publishable key belongs in the frontend. Never place the service-role key or Resend API key in HTML. RLS prevents public users from reading the guest list. Only users inserted into `admin_users` can access RSVP records.
