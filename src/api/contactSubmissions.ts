import { supabase } from '../lib/supabase';

export interface ContactFormData {
  name: string;
  email: string;
  company?: string;
  phone?: string;
  fleetSize?: string;
  inquiryType: string;
  message?: string;
}

export const createContactSubmission = async (data: ContactFormData): Promise<{ success: boolean; error?: string }> => {
  try {
    const { error } = await supabase.from('contact_submissions').insert([
      {
        name: data.name,
        email: data.email,
        company: data.company,
        phone: data.phone,
        fleet_size: data.fleetSize,
        inquiry_type: data.inquiryType,
        message: data.message,
        status: 'new',
      },
    ]);

    if (error) {
      console.error('Error creating contact submission:', error);
      return { success: false, error: error.message };
    }

    return { success: true };
  } catch (error) {
    console.error('Error creating contact submission:', error);
    return { success: false, error: 'Failed to submit contact form' };
  }
};
