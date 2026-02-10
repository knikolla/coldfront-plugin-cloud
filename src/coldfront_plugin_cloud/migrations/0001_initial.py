# Generated manually for coldfront_plugin_cloud

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('allocation', '__first__'),
    ]

    operations = [
        migrations.CreateModel(
            name='UsageInfo',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField(help_text='The date for which this usage was recorded')),
                ('su_type', models.CharField(help_text='The type of Service Unit (e.g., OpenStack CPU, OpenStack V100 GPU)', max_length=255)),
                ('value', models.DecimalField(decimal_places=2, help_text='The usage value/cost for this SU type on this date', max_digits=12)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('allocation', models.ForeignKey(help_text='The allocation this usage belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='usage_info', to='allocation.allocation')),
            ],
            options={
                'db_table': 'coldfront_plugin_cloud_usageinfo',
                'ordering': ['-date', 'allocation', 'su_type'],
            },
        ),
        migrations.AddIndex(
            model_name='usageinfo',
            index=models.Index(fields=['allocation', 'date'], name='coldfront_p_allocat_5c8e3d_idx'),
        ),
        migrations.AddIndex(
            model_name='usageinfo',
            index=models.Index(fields=['date'], name='coldfront_p_date_3e8a9e_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='usageinfo',
            unique_together={('allocation', 'date', 'su_type')},
        ),
    ]
